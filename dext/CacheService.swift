import Foundation

class CacheService {
    private let fileName = "pokemon_list.json"
    
    private var fileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func save(pokemon: [Pokemon]) {
        guard let url = fileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(pokemon)
            try data.write(to: url)
            print("Successfully saved \(pokemon.count) pokemon to cache.")
        } catch {
            print("Failed to save cache: \(error.localizedDescription)")
        }
    }
    
    func load() -> [Pokemon]? {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let pokemon = try JSONDecoder().decode([Pokemon].self, from: data)
            print("Successfully loaded \(pokemon.count) pokemon from cache.")
            return pokemon
        } catch {
            print("Failed to load cache: \(error.localizedDescription)")
            return nil
        }
    }
}
