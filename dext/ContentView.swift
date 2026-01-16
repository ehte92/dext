import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.filteredPokemon) { pokemon in
                        PokemonRowView(pokemon: pokemon)
                            .onAppear {
                                if viewModel.searchText.isEmpty && viewModel.hasReachedEnd(of: pokemon) {
                                    viewModel.loadMore()
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding() // Restore default padding (horizontal + vertical) to fix edge stretching
            }
            .navigationTitle("Pokédex")
            .background(Color(UIColor.systemGroupedBackground))
            .searchable(text: $viewModel.searchText, prompt: "Search Pokemon")
            .onAppear {
                if viewModel.pokemonList.isEmpty {
                    viewModel.loadMore()
                }
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

#Preview {
    ContentView()
}
