import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        NavigationStack {
            DestinationsListView()
        }
        .environmentObject(store)
        .tint(Palette.primary)
        .scrollDismissesKeyboard(.immediately)
    }
}
