import SwiftUI

struct AbilityDexView: View {
    var body: some View {
        VStack {
            Image(systemName: "bolt")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Ability Dex")
                .font(.title)
            Text("Coming Soon")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Abilities")
    }
}

#Preview {
    NavigationStack {
        AbilityDexView()
    }
}
