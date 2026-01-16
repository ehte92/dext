import SwiftUI

struct FilterView: View {
    @Binding var config: FilterConfig
    @Binding var isPresented: Bool
    var onApply: () -> Void
    
    let types = [
        "Normal", "Fire", "Water", "Electric", "Grass", "Ice",
        "Fighting", "Poison", "Ground", "Flying", "Psychic",
        "Bug", "Rock", "Ghost", "Dragon", "Steel", "Fairy"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sort By")) {
                    Picker("Criteria", selection: $config.sortOption) {
                        ForEach(FilterConfig.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Order", selection: $config.sortOrder) {
                        ForEach(FilterConfig.SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Filter By Type")) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(types, id: \.self) { type in
                            TypeFilterChip(
                                type: type,
                                isSelected: config.typeFilters.contains(type.lowercased())
                            ) {
                                toggleType(type.lowercased())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Reset Filters") {
                        config = FilterConfig()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func toggleType(_ type: String) {
        if config.typeFilters.contains(type) {
            config.typeFilters.remove(type)
        } else {
            config.typeFilters.insert(type)
        }
    }
}

struct TypeFilterChip: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.from(name: type.lowercased()) : Color.gray.opacity(0.1))
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterView(config: .constant(FilterConfig()), isPresented: .constant(true), onApply: {})
}
