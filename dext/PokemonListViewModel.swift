import Foundation
import Combine

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemonList: [Pokemon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = PokemonService()
    private var offset = 0
    private let limit = 20
    private var canLoadMore = true
    
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
                                
                                // Sort variants: Default first, then by ID or name?
                                // Usually we want standard first. `is_default` helps.
                                // But `PokemonSpeciesVariety` struct had `is_default`.
                                // Let's just assume the API order or sort standard first.
                                // API usually puts default first.
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
                    // We want: Species 1 (All Variants), Species 2 (All Variants)...
                    var orderedResults: [Pokemon] = []
                    for species in speciesList {
                        // Find all pokemon belonging to this species ID
                        let belongingToSpecies = results.filter { $0.speciesId == species.id }
                        
                        // Sort them: Default first? We lost `is_default` unless we store it.
                        // However, usually the default form has the same ID as the species (for Gen 1-7).
                        // Let's sort by ID, usually base form has lower ID than Mega (10000+).
                        let sorted = belongingToSpecies.sorted { $0.id < $1.id }
                        orderedResults.append(contentsOf: sorted)
                    }
                    
                    return orderedResults
                }
                
                pokemonList.append(contentsOf: newPokemon)
                offset += limit
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
