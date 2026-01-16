import SwiftUI

struct ContentView: View {
    @State private var currentScreen: AppScreen = .pokedex
    @State private var isMenuPresented = false

    var body: some View {
        NavigationStack {
            Group {
                switch currentScreen {
                case .pokedex:
                    PokedexView()
                case .moves:
                    MoveDexView()
                case .abilities:
                    AbilityDexView()
                case .settings:
                    SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isMenuPresented = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $isMenuPresented) {
                MenuView(currentScreen: $currentScreen, isPresented: $isMenuPresented)
                    .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
            }
        }
    }
}

#Preview {
    ContentView()
}
