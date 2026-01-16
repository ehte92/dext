import SwiftUI

struct MenuView: View {
    @Binding var currentScreen: AppScreen
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Dext")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your Pokémon Companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .padding(.top, 10)
            
            Divider()
                .padding(.bottom, 16)
            
            // Items
            VStack(spacing: 8) {
                ForEach(AppScreen.allCases) { screen in
                    Button {
                        currentScreen = screen
                        isPresented = false
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: screen.icon)
                                .font(.title3)
                                .frame(width: 24)
                            
                            Text(screen.title)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .foregroundStyle(currentScreen == screen ? Color.blue : Color.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(currentScreen == screen ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
            
            // Footer
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    MenuView(currentScreen: .constant(.pokedex), isPresented: .constant(true))
}
