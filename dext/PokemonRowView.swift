import SwiftUI

struct PokemonRowView: View {
    let pokemon: Pokemon
    
    var body: some View {
        let backgroundColor = Color.from(name: pokemon.mainColor ?? pokemon.types?.first ?? "normal")
        
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Decorative Circle for Image
            HStack {
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .offset(x: 30) // Only horizontal push
            }
            .clipShape(RoundedRectangle(cornerRadius: 16)) // Clip to card bounds
            
            HStack(spacing: 0) {
                // Left Side: Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(pokemon.formattedId)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.black.opacity(0.2))
                        
                        Text(pokemon.capitalizedName)
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    
                    // Type Badges (Pills)
                    if let types = pokemon.types {
                        HStack {
                            ForEach(types, id: \.self) { type in
                                Text(type.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    } else {
                        // Skeleton placeholder for types if loading
                         Text("LOADING...")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // Right Side: Image
                AsyncImage(url: pokemon.imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 68, height: 68)
                            .shadow(radius: 4)
                    case .failure:
                        Image(systemName: "questionmark.circle")
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white.opacity(0.5))
                    @unknown default:
                         EmptyView()
                    }
                }
                .padding(.trailing, 10)
            }
            // Removing vertical padding here to let the frame control height tightly
        }
        .frame(height: 76) // Enforce compact height
        .clipShape(RoundedRectangle(cornerRadius: 16)) // Clip overflow while keeping rounded corners
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack {
            PokemonRowView(pokemon: Pokemon(
                name: "bulbasaur",
                url: "https://pokeapi.co/api/v2/pokemon/1/",
                types: ["grass", "poison"],
                mainColor: "green"
            ))
            
             PokemonRowView(pokemon: Pokemon(
                name: "charmander",
                url: "https://pokeapi.co/api/v2/pokemon/4/",
                types: ["fire"],
                mainColor: "red"
            ))
        }
        .padding()
    }
}
