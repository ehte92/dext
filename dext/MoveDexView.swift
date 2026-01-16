import SwiftUI

struct MoveDexView: View {
    var body: some View {
        VStack {
            Image(systemName: "flame")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Move Dex")
                .font(.title)
            Text("Coming Soon")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Moves")
    }
}

#Preview {
    NavigationStack {
        MoveDexView()
    }
}
