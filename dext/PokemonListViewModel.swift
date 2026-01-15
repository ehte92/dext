import Foundation
import Combine

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemonList: [Pokemon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = PokemonService()
    private let cacheService = CacheService()
    private var offset = 0
    private let limit = 20
    private var canLoadMore = true
    
    init() {
        loadCache()
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
