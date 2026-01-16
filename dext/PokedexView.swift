import SwiftUI

struct PokedexView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    
    var body: some View {
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
            .padding()
        }
        .navigationTitle("Dext")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Pokemon")
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

#Preview {
    NavigationStack {
        PokedexView()
    }
}
