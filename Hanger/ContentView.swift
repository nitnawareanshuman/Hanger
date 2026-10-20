import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem { Label("Wardrobe", systemImage: "hanger") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "sparkles") }
        }
        .tint(Color.wardrobeAccent)
    }
}

#Preview {
    ContentView().modelContainer(WardrobeSampleData.previewContainer)
}
