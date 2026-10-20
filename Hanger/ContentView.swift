import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        WardrobeView()
    }
}

#Preview {
    ContentView().modelContainer(WardrobeSampleData.previewContainer)
}
