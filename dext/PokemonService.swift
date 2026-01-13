import Foundation

class PokemonService {
    private let baseURL = "https://pokeapi.co/api/v2/pokemon"
    
    func fetchPokemon(limit: Int = 20, offset: Int = 0) async throws -> [Pokemon] {
        guard let url = URL(string: "\(baseURL)?limit=\(limit)&offset=\(offset)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let listResponse = try decoder.decode(PokemonListResponse.self, from: data)
        
        return listResponse.results
    }
    
    func fetchPokemonDetails(id: Int) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let detailResponse = try decoder.decode(PokemonDetailResponse.self, from: data)
        
        return detailResponse.types.map { $0.type.name }
    }
    
    func fetchPokemonSpecies(id: Int) async throws -> String {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon-species/\(id)/") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let speciesResponse = try decoder.decode(PokemonSpeciesResponse.self, from: data)
        
        return speciesResponse.color.name
    }
}
