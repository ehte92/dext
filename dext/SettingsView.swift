import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("General")) {
                Text("Version 1.0.0")
            }
            
            Section(header: Text("About")) {
                Text("Dext - Your Pokemon Companion")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
