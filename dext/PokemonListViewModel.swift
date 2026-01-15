import Foundation
import Combine

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemonList: [Pokemon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = "" {
        didSet {
            performSearch()
        }
    }
    
    private let service = PokemonService()
    private let cacheService = CacheService()
    private var offset = 0
    private let limit = 20
    private var canLoadMore = true
    
    // Global Index for Search
    private var allPokemonRefs: [Pokemon] = []
    @Published var searchResults: [Pokemon] = []
    
    var filteredPokemon: [Pokemon] {
        if searchText.isEmpty {
            return pokemonList
        } else {
            return searchResults
        }
    }
    
    init() {
        loadCache()
        loadGlobalIndex()
    }
    
    private func loadGlobalIndex() {
        Task {
            do {
                allPokemonRefs = try await service.fetchAllPokemonRefs()
            } catch {
                print("Failed to load global index: \(error)")
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        // 1. Filter local refs
        let query = searchText.lowercased()
        let matches = allPokemonRefs.filter { pokemon in
            pokemon.name.localizedCaseInsensitiveContains(query) ||
            "\(pokemon.id)".contains(query)
        }
        
        // 2. Set results immediately (skeletons)
        // Limit to reasonable number to prevent UI lag on massive results
        self.searchResults = Array(matches.prefix(50))
        
        // 3. Fetch Details for top results
        fetchDetailsForSearch(results: self.searchResults)
    }
     
    private func fetchDetailsForSearch(results: [Pokemon]) {
        Task {
            // Fetch for top 20 visible
            let topResults = results.prefix(20)
             
            await withTaskGroup(of: Pokemon.self) { group in
                for var pokemon in topResults {
                    // Check if we already have it in main list (optimization)
                    // Performed on MainActor BEFORE entering the background task
                    let existing = self.pokemonList.first(where: { $0.id == pokemon.id })
                    
                    group.addTask { [existing, pokemon] in
                         if let existing = existing {
                             return existing
                         }
                         
                         var pokemon = pokemon
                         
                        do {
                            // It's a raw Pokemon ref, so `pokemon.speciesId` is nil.
                            // We need to fetch details to get Types and Color.
                            // Note: `fetchPokemonDetails` returns [Type]. `fetchPokemonSpecies` returns Color.
                            // But for Global Search results (which are /pokemon items), we want to show them like normal cards.
                            
                            // 1. Fetch Types
                            async let types = self.service.fetchPokemonDetails(id: pokemon.id)
                            
                            // 2. Fetch Species (to get Color AND Species ID if possible)
                            // Note: We don't know the species ID yet. But usually it matches or we can look it up.
                            // For /pokemon/10033 (Mega), the species is /pokemon-species/3.
                            // We can fetch the Pokemon object /pokemon/{id} to get the species url, but simpler is:
                            // Just fetch species info. However, `fetchPokemonSpecies(id:)` takes an ID.
                            // If we pass 10033 to `pokemon-species/`, it 404s.
                            // So we need to handle that.
                            
                            // Simplified approach for search: Just get Types -> "Unknown" color if fail.
                            // Or default color based on Type.
                            // Let's try to fetch types first.
                            pokemon.types = try await types
                            
                            // Approximate color from Type?
                            // Or try to fetch species if ID <= 1025.
                            // If ID > 10000, it's a variant.
                            
                            // Let's rely on Type Color fallback if Species fetch fails.
                            if pokemon.id <= 1025 {
                                let species = try await self.service.fetchPokemonSpecies(id: pokemon.id)
                                pokemon.mainColor = species.color.name
                                pokemon.speciesId = species.id
                            } else {
                                // For variants, color lookup is harder without fetching the full Pokemon object.
                                // Fallback to Type color is fine.
                            }
                            
                            return pokemon
                        } catch {
                            // If failed, return as is (will show Loading/Skeleton)
                            return pokemon
                        }
                    }
                }
                
                var detailedResults: [Pokemon] = []
                for await p in group {
                    detailedResults.append(p)
                }
                
                // Update Search Results with details
                DispatchQueue.main.async {
                    // Update the structs in the array
                     self.searchResults = self.searchResults.map { original in
                         detailedResults.first(where: { $0.id == original.id }) ?? original
                     }
                }
            }
        }
    }
    
    private func loadCache() {
        if let cachedPokemon = cacheService.load() {
            self.pokemonList = cachedPokemon
            self.offset = cachedPokemon.count
            // If we have cached data, we might be at the end, or we can load more.
            // Usually safest to assume we can load more if we have data.
            // But if cached count is 0, offset is 0.
        }
    }
    
    func loadMoreInternal() async {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Species List (instead of Pokemon list)
            let speciesList = try await service.fetchSpeciesList(limit: limit, offset: offset)
            
            if speciesList.isEmpty {
                canLoadMore = false
            } else {
                // 2. Fetch details for each species (Parallel)
                let newPokemon = await withTaskGroup(of: [Pokemon].self) { group in
                    for species in speciesList {
                        group.addTask {
                            do {
                                // Fetch Species Details (Variation + Color)
                                let speciesDetails = try await self.service.fetchPokemonSpecies(id: species.id)
                                
                                // Expand Varieties
                                var variants: [Pokemon] = []
                                
                                // Iterate through all varieties
                                for var variety in speciesDetails.varieties {
                                    var p = variety.pokemon
                                    p.speciesId = species.id
                                    p.mainColor = speciesDetails.color.name
                                    
                                    // Fetch Types for this specific variant
                                    // Note: This adds N calls per species, but concurrent
                                    if let types = try? await self.service.fetchPokemonDetails(id: p.id) {
                                        p.types = types
                                    }
                                    
                                    variants.append(p)
                                }
                                
                                // Sort variants
                                return variants
                            } catch {
                                print("Failed to fetch species details for \(species.name): \(error)")
                                return []
                            }
                        }
                    }
                    
                    var results: [Pokemon] = []
                    for await batch in group {
                        results.append(contentsOf: batch)
                    }
                    
                    // Restore Species Order (Crucial for list consistency)
                    var orderedResults: [Pokemon] = []
                    for species in speciesList {
                        let belongingToSpecies = results.filter { $0.speciesId == species.id }
                        let sorted = belongingToSpecies.sorted { $0.id < $1.id }
                        orderedResults.append(contentsOf: sorted)
                    }
                    
                    return orderedResults
                }
                
                pokemonList.append(contentsOf: newPokemon)
                offset += limit
                
                // Save to Cache
                cacheService.save(pokemon: pokemonList)
            }
        } catch {
            errorMessage = "Failed to load Pokemon: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMore() {
        Task {
            await loadMoreInternal()
        }
    }
    
    func hasReachedEnd(of pokemon: Pokemon) -> Bool {
        return pokemonList.last == pokemon
    }
}
