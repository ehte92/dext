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
            let newPokemon = try await service.fetchPokemon(limit: limit, offset: offset)
            if newPokemon.isEmpty {
                canLoadMore = false
            } else {
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
