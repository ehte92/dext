import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.pokemonList) { pokemon in
                        PokemonRowView(pokemon: pokemon)
                            .onAppear {
                                if viewModel.hasReachedEnd(of: pokemon) {
                                    viewModel.loadMore()
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Pokédex")
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
