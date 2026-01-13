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
            var newPokemon = try await service.fetchPokemon(limit: limit, offset: offset)
            
            if newPokemon.isEmpty {
                canLoadMore = false
            } else {
                // Fetch details in parallel
                newPokemon = await withTaskGroup(of: Pokemon.self) { group in
                    for var pokemon in newPokemon {
                        group.addTask {
                            do {
                                // Concurrent fetch of independent details
                                async let types = self.service.fetchPokemonDetails(id: pokemon.id)
                                async let color = self.service.fetchPokemonSpecies(id: pokemon.id)
                                
                                pokemon.types = try await types
                                pokemon.mainColor = try await color
                                return pokemon
                            } catch {
                                print("Failed to fetch details for \(pokemon.name): \(error)")
                                return pokemon
                            }
                        }
                    }
                    
                    var results: [Pokemon] = []
                    for await pokemon in group {
                        results.append(pokemon)
                    }
                    
                    // Restore original order
                    return newPokemon.map { original in
                        results.first(where: { $0.id == original.id }) ?? original
                    }
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
