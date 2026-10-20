import SwiftUI
import SwiftData

@main
struct HangerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Creates the on-disk SwiftData store that @Query / modelContext rely on.
        .modelContainer(for: Garment.self)
    }
}
