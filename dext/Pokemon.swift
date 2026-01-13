import Foundation

struct Pokemon: Identifiable, Codable, Equatable {
    let name: String
    let url: String
    
    var id: Int {
        // Extract ID from URL (e.g., https://pokeapi.co/api/v2/pokemon/1/)
        guard let urlComponent = URL(string: url),
              let id = Int(urlComponent.lastPathComponent) else {
            return 0
        }
        return id
    }
    
    var imageUrl: URL? {
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")
    }
    
    // Formatting the name to be capitalized
    var capitalizedName: String {
        return name.capitalized
    }
}

struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Pokemon]
}
