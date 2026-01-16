import Foundation

enum AppScreen: CaseIterable, Identifiable {
    case pokedex
    case moves
    case abilities
    case settings
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .pokedex: return "Pokédex"
        case .moves: return "Moves"
        case .abilities: return "Abilities"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .pokedex: return "list.bullet"
        case .moves: return "flame"
        case .abilities: return "bolt"
        case .settings: return "gear"
        }
    }
}
