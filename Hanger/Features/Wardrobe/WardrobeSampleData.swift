import SwiftData
import SwiftUI

enum WardrobeSampleData {
    static let garments: [Garment] = [
        Garment(name: "Linen shirt", category: .tops, colorHex: "#D8C5A5", season: .summer, imageFilename: "", wearCount: 12, tags: ["linen", "casual"]),
        Garment(name: "Everyday tee", category: .tops, colorHex: "#A8B5A0", season: .allSeason, imageFilename: "", wearCount: 24, tags: ["basic", "cotton"]),
        Garment(name: "Denim jacket", category: .outerwear, colorHex: "#617D9C", season: .autumn, imageFilename: "", wearCount: 8, tags: ["denim", "layer"]),
        Garment(name: "Knit cardigan", category: .outerwear, colorHex: "#B9856C", season: .winter, imageFilename: "", wearCount: 5, tags: ["knit", "warm"]),
        Garment(name: "Black trousers", category: .bottoms, colorHex: "#373A3C", season: .allSeason, imageFilename: "", wearCount: 18, tags: ["tailored", "work"]),
        Garment(name: "Relaxed denim", category: .bottoms, colorHex: "#7794AC", season: .allSeason, imageFilename: "", wearCount: 15, tags: ["denim", "casual"]),
        Garment(name: "Canvas sneakers", category: .shoes, colorHex: "#E7E1D4", season: .allSeason, imageFilename: "", wearCount: 31, tags: ["everyday"]),
        Garment(name: "Leather loafers", category: .shoes, colorHex: "#80563D", season: .allSeason, imageFilename: "", wearCount: 7, tags: ["formal"]),
        Garment(name: "Silver watch", category: .accessories, colorHex: "#9DA4A7", season: .allSeason, imageFilename: "", wearCount: 42, tags: ["daily"]),
        Garment(name: "Crossbody bag", category: .bags, colorHex: "#8C6248", season: .allSeason, imageFilename: "", wearCount: 11, tags: ["leather"]),
        Garment(name: "Weekend tote", category: .bags, colorHex: "#C1A17B", season: .summer, imageFilename: "", wearCount: 3, tags: ["canvas"]),
        Garment(name: "Knit dress", category: .dresses, colorHex: "#A96665", season: .winter, imageFilename: "", wearCount: 0, tags: ["knit", "occasion"])
    ]

    @MainActor
    static var previewContainer: ModelContainer = {
        let schema = Schema([Garment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        for garment in garments { container.mainContext.insert(garment) }
        return container
    }()
}
