import Foundation
import SwiftUI

extension Color {
    static func from(name: String) -> Color {
        switch name {
        // API Colors
        case "black": return Color(red: 0.2, green: 0.2, blue: 0.2)
        case "blue": return Color(red: 0.40, green: 0.56, blue: 0.94)
        case "brown": return Color(red: 0.65, green: 0.40, blue: 0.25) // Adjusted Brown
        case "gray": return Color(red: 0.6, green: 0.6, blue: 0.6)
        case "green": return Color(red: 0.48, green: 0.78, blue: 0.30)
        case "pink": return Color(red: 0.98, green: 0.65, blue: 0.76) // Jigglypuff Pink
        case "purple": return Color(red: 0.64, green: 0.24, blue: 0.63)
        case "red": return Color(red: 0.93, green: 0.40, blue: 0.30)
        case "white": return Color(red: 0.9, green: 0.9, blue: 0.9) // Off-white
        case "yellow": return Color(red: 0.97, green: 0.85, blue: 0.20)
            
        // Fallback Types (legacy support)
        case "normal": return Color(red: 0.66, green: 0.65, blue: 0.48)
        case "fire": return Color(red: 0.93, green: 0.50, blue: 0.19)
        case "water": return Color(red: 0.40, green: 0.56, blue: 0.94)
        case "electric": return Color(red: 0.97, green: 0.82, blue: 0.17)
        case "grass": return Color(red: 0.48, green: 0.78, blue: 0.30)
        case "ice": return Color(red: 0.58, green: 0.85, blue: 0.84)
        case "fighting": return Color(red: 0.76, green: 0.18, blue: 0.16)
        case "poison": return Color(red: 0.64, green: 0.24, blue: 0.63)
        case "ground": return Color(red: 0.88, green: 0.75, blue: 0.40)
        case "flying": return Color(red: 0.66, green: 0.56, blue: 0.94)
        case "psychic": return Color(red: 0.98, green: 0.33, blue: 0.53)
        case "bug": return Color(red: 0.66, green: 0.73, blue: 0.10)
        case "rock": return Color(red: 0.71, green: 0.63, blue: 0.21)
        case "ghost": return Color(red: 0.45, green: 0.34, blue: 0.59)
        case "dragon": return Color(red: 0.43, green: 0.21, blue: 0.96)
        case "steel": return Color(red: 0.71, green: 0.71, blue: 0.81)
        case "fairy": return Color(red: 0.84, green: 0.52, blue: 0.68)
        
        default: return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
    
    static func textContrastColor(for name: String) -> Color {
        switch name.lowercased() {
        case "white", "normal": return Color(red: 0.2, green: 0.2, blue: 0.25) // Dark Charcoal
        case "yellow", "electric": return Color(red: 0.4, green: 0.3, blue: 0.1) // Dark Brown
        case "pink", "fairy": return Color(red: 0.5, green: 0.2, blue: 0.3) // Dark Maroon
        default: return .white
        }
    }
}

struct Pokemon: Identifiable, Codable, Equatable {
    let name: String
    let url: String
    
    var speciesId: Int?
    
    var id: Int {
        // Extract ID from URL (e.g., https://pokeapi.co/api/v2/pokemon/1/)
        guard let urlComponent = URL(string: url),
              let id = Int(urlComponent.lastPathComponent) else {
            return 0
        }
        return id
    }
    
    var imageUrl: URL? {
        // High quality "Official Artwork"
        return URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
    
    // Formatting the name to be capitalized
    var capitalizedName: String {
        // Handle Variants like "venusaur-mega" -> "Mega Venusaur"
        if name.hasSuffix("-mega") {
            return "Mega \(name.dropLast(5).capitalized)"
        }
        if name.hasSuffix("-gmax") {
            return "Gigantamax \(name.dropLast(5).capitalized)"
        }
        if name.hasSuffix("-alola") {
            return "Alolan \(name.dropLast(6).capitalized)"
        }
        if name.hasSuffix("-galar") {
            return "Galarian \(name.dropLast(6).capitalized)"
        }
        if name.hasSuffix("-hisui") {
            return "Hisuian \(name.dropLast(6).capitalized)"
        }
        if name.hasSuffix("-paldea") {
            return "Paldean \(name.dropLast(7).capitalized)"
        }
        
        // Handle "alola", "galar", "hisui" suffix patterns if needed, or simple replacement
        return name.capitalized.replacingOccurrences(of: "-", with: " ")
    }
    
    var formattedId: String {
        if let speciesId = speciesId {
            return String(format: "#%03d", speciesId)
        }
        return String(format: "#%03d", id)
    }
    
    var types: [String]?
    var mainColor: String?
}

struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Pokemon]
}

struct PokemonDetailResponse: Codable {
    let types: [TypeElement]
}

struct TypeElement: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}

struct PokemonSpeciesResponse: Codable {
    let color: SpeciesColor
    let varieties: [PokemonSpeciesVariety]
}

struct SpeciesColor: Codable {
    let name: String
}

struct PokemonSpeciesVariety: Codable {
    let is_default: Bool
    let pokemon: Pokemon
}
