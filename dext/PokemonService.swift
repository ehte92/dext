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
    
    func fetchPokemonSpecies(id: Int) async throws -> PokemonSpeciesResponse {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon-species/\(id)/") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PokemonSpeciesResponse.self, from: data)
    }
    
    func fetchSpeciesList(limit: Int, offset: Int) async throws -> [Pokemon] {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon-species?limit=\(limit)&offset=\(offset)") else {
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
    
    func fetchAllPokemonRefs() async throws -> [Pokemon] {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=2000") else {
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
    
    func fetchPokemonByType(type: String) async throws -> [Pokemon] {
        guard let url = URL(string: "https://pokeapi.co/api/v2/type/\(type)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct TypeResponse: Decodable {
            struct PokemonSlot: Decodable {
                let pokemon: Pokemon
            }
            let pokemon: [PokemonSlot]
        }
        
        let decoder = JSONDecoder()
        let typeResponse = try decoder.decode(TypeResponse.self, from: data)
        return typeResponse.pokemon.map { $0.pokemon }
    }
}
