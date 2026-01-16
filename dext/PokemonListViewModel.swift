import Foundation
import Combine

struct FilterConfig {
    enum SortOption: String, CaseIterable, Identifiable {
        case id = "Number"
        case name = "Name"
        var id: String { rawValue }
    }
    
    enum SortOrder: String, CaseIterable, Identifiable {
        case ascending = "Ascending"
        case descending = "Descending"
        var id: String { rawValue }
    }
    
    var sortOption: SortOption = .id
    var sortOrder: SortOrder = .ascending
    var typeFilters: Set<String> = [] // Changed to Set for multi-select
    
    var isDefault: Bool {
        sortOption == .id && sortOrder == .ascending && typeFilters.isEmpty
    }
}

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var pokemonList: [Pokemon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = "" {
        didSet {
            performSearch()
        }
    }
    
    @Published var filterConfig = FilterConfig()
    @Published var isFilterPresented = false
    
    private let service = PokemonService()
    private let cacheService = CacheService()
    private var offset = 0
    private let limit = 20
    private var canLoadMore = true
    
    // Global Index for Search/Flat Sorting
    private var allPokemonRefs: [Pokemon] = []
    private var sortedFlatRefs: [Pokemon] = [] // The full sorted list we paginate through
    @Published var searchResults: [Pokemon] = []
    
    var filteredPokemon: [Pokemon] {
        if searchText.isEmpty {
            return pokemonList
        } else {
            return searchResults
        }
    }
    
    init() {
        // Initial load relies on defaults (Species paging)
        loadCache()
        loadGlobalIndex()
    }
    
    private func loadGlobalIndex() {
        Task {
            do {
                allPokemonRefs = try await service.fetchAllPokemonRefs()
            } catch {
                print("Failed to load global index: \(error)")
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let query = searchText.lowercased()
        let matches = allPokemonRefs.filter { pokemon in
            pokemon.name.localizedCaseInsensitiveContains(query) ||
            "\(pokemon.id)".contains(query)
        }
        
        self.searchResults = Array(matches.prefix(50))
        fetchDetailsForList(refs: self.searchResults, isSearch: true)
    }
    
    // MARK: - Sorting & Filtering Application
    
    func applyFilters() {
        isLoading = true
        pokemonList = []
        offset = 0
        canLoadMore = true
        errorMessage = nil
        
        Task {
            do {
                if filterConfig.isDefault {
                    // Revert to Default "Species" Paging
                    isLoading = false // Reset before loading
                    await loadMoreInternal()
                } else {
                    // Flat Mode
                    
                    // 1. Get Base List (All or Type Union)
                    var baseList: [Pokemon] = []
                    
                    if filterConfig.typeFilters.isEmpty {
                        // Ensure global index is ready, or fetch it
                        if allPokemonRefs.isEmpty {
                            allPokemonRefs = try await service.fetchAllPokemonRefs()
                        }
                        baseList = allPokemonRefs
                    } else {
                        // Multi-Type Filter (OR Logic)
                        // Fetch all selected types in parallel
                        let types = Array(filterConfig.typeFilters)
                        
                        // Use TaskGroup to fetch each type list
                        baseList = await withTaskGroup(of: [Pokemon].self) { group in
                            for type in types {
                                group.addTask {
                                    do {
                                        return try await self.service.fetchPokemonByType(type: type)
                                    } catch {
                                        print("Error fetching type \(type): \(error)")
                                        return []
                                    }
                                }
                            }
                            
                            var combined: Set<Int> = [] // Track IDs to avoid duplicates if Pokemon has 2 selected types
                            var uniqueList: [Pokemon] = []
                            
                            for await list in group {
                                for p in list {
                                    if !combined.contains(p.id) {
                                        combined.insert(p.id)
                                        uniqueList.append(p)
                                    }
                                }
                            }
                            return uniqueList
                        }
                    }
                    
                    // 2. Sort
                    switch filterConfig.sortOption {
                    case .id:
                        baseList.sort { $0.id < $1.id }
                    case .name:
                        baseList.sort { $0.name < $1.name }
                    }
                    
                    if filterConfig.sortOrder == .descending {
                        baseList.reverse()
                    }
                    
                    self.sortedFlatRefs = baseList
                    
                    // 3. Load first page
                    // Important: Reset loading state so loadMoreFlat can start cleanly
                    isLoading = false 
                    await loadMoreFlat()
                }
            } catch {
                errorMessage = "Failed to apply filters: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Paging Logic
    
    func loadMore() {
        Task {
            if filterConfig.isDefault {
                await loadMoreInternal()
            } else {
                await loadMoreFlat()
            }
        }
    }
    
    private func loadMoreFlat() async {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        
        let end = min(offset + limit, sortedFlatRefs.count)
        guard offset < end else {
            canLoadMore = false
            isLoading = false
            return
        }
        
        let pageRefs = Array(sortedFlatRefs[offset..<end])
        
        // Add skeletons immediately
        self.pokemonList.append(contentsOf: pageRefs)
        let currentBatchStartIndex = self.pokemonList.count - pageRefs.count
        
        // Fetch details for this batch
        await fetchDetailsForList(refs: pageRefs, startIndex: currentBatchStartIndex)
        
        offset += limit
        if offset >= sortedFlatRefs.count {
            canLoadMore = false
        }
        
        isLoading = false
    }
    
    // General purpose fetcher for Flat Lists (Search or Sorted)
    private func fetchDetailsForList(refs: [Pokemon], startIndex: Int = 0, isSearch: Bool = false) {
        Task {
            let detailedResults = await withTaskGroup(of: Pokemon.self) { group in
                for pokemon in refs {
                    group.addTask {
                        var p = pokemon
                        do {
                            // Fetch Types
                            if let types = try? await self.service.fetchPokemonDetails(id: p.id) {
                                p.types = types
                            }
                            
                            // Fetch Species for Color/ID (Only if ID reasonable)
                            if p.id <= 10000 {
                                if let species = try? await self.service.fetchPokemonSpecies(id: p.id) {
                                    p.mainColor = species.color.name
                                    p.speciesId = species.id
                                }
                            }
                            return p
                        } catch {
                            return p
                        }
                    }
                }
                
                var results: [Pokemon] = []
                for await p in group {
                    results.append(p)
                }
                return results
            }
            
            DispatchQueue.main.async {
                if isSearch {
                     // Update search results in place
                     self.searchResults = self.searchResults.map { original in
                         detailedResults.first(where: { $0.id == original.id }) ?? original
                     }
                } else {
                    // Update main list in place
                    // We know the range we just added [startIndex ..< startIndex+count]
                    for detail in detailedResults {
                        if let idx = self.pokemonList.firstIndex(where: { $0.id == detail.id }) {
                            self.pokemonList[idx] = detail
                        }
                    }
                }
            }
        }
    }
    
    private func loadCache() {
        if let cachedPokemon = cacheService.load() {
            self.pokemonList = cachedPokemon
            self.offset = cachedPokemon.count
        }
    }
    
    // Original "Species-based" paging (Grouped by default)
    func loadMoreInternal() async {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Species List
            let speciesList = try await service.fetchSpeciesList(limit: limit, offset: offset)
            
            if speciesList.isEmpty {
                canLoadMore = false
            } else {
                // 2. Fetch details for each species (Parallel)
                let newPokemon = await withTaskGroup(of: [Pokemon].self) { group in
                    for species in speciesList {
                        group.addTask {
                            do {
                                let speciesDetails = try await self.service.fetchPokemonSpecies(id: species.id)
                                var variants: [Pokemon] = []
                                
                                for var variety in speciesDetails.varieties {
                                    var p = variety.pokemon
                                    p.speciesId = species.id
                                    p.mainColor = speciesDetails.color.name
                                    
                                    if let types = try? await self.service.fetchPokemonDetails(id: p.id) {
                                        p.types = types
                                    }
                                    variants.append(p)
                                }
                                return variants
                            } catch {
                                return []
                            }
                        }
                    }
                    
                    var results: [Pokemon] = []
                    for await batch in group {
                        results.append(contentsOf: batch)
                    }
                    
                    // Re-sort by species ID to maintain list order
                    var orderedResults: [Pokemon] = []
                    for species in speciesList {
                        let belonging = results.filter { $0.speciesId == species.id }
                        let sorted = belonging.sorted { $0.id < $1.id }
                        orderedResults.append(contentsOf: sorted)
                    }
                    
                    return orderedResults
                }
                
                pokemonList.append(contentsOf: newPokemon)
                offset += limit
                
                // Only save cache in default mode
                cacheService.save(pokemon: pokemonList)
            }
        } catch {
            errorMessage = "Failed to load Pokemon: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func hasReachedEnd(of pokemon: Pokemon) -> Bool {
        return pokemonList.last == pokemon
    }
}
