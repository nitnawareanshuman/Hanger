import SwiftData
import SwiftUI

/// Demo content. Garments are created fresh on every call because SwiftData models are
/// reference types and must not be inserted into more than one container.
enum WardrobeSampleData {
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    static func makeGarments() -> [Garment] {
        [
            Garment(name: "Linen shirt", category: .tops, colorHex: "#D8C5A5", season: .summer, imageFilename: "", wearCount: 12, lastWornDate: daysAgo(14), createdAt: daysAgo(300), tags: ["linen", "casual"]),
            Garment(name: "Everyday tee", category: .tops, colorHex: "#A8B5A0", season: .allSeason, imageFilename: "", wearCount: 24, lastWornDate: daysAgo(3), createdAt: daysAgo(500), tags: ["basic", "cotton"]),
            Garment(name: "White oxford shirt", category: .tops, colorHex: "#F2F0EA", season: .allSeason, imageFilename: "", wearCount: 2, lastWornDate: daysAgo(260), createdAt: daysAgo(420), tags: ["formal", "cotton"]),
            Garment(name: "White crew tee", category: .tops, colorHex: "#F4F4F2", season: .summer, imageFilename: "", wearCount: 1, lastWornDate: daysAgo(300), createdAt: daysAgo(380), tags: ["basic"]),
            Garment(name: "Striped Breton top", category: .tops, colorHex: "#2E4A6B", season: .spring, imageFilename: "", wearCount: 0, createdAt: daysAgo(200), tags: ["striped"]),
            Garment(name: "Denim jacket", category: .outerwear, colorHex: "#617D9C", season: .autumn, imageFilename: "", wearCount: 8, lastWornDate: daysAgo(40), createdAt: daysAgo(600), tags: ["denim", "layer"]),
            Garment(name: "Knit cardigan", category: .outerwear, colorHex: "#B9856C", season: .winter, imageFilename: "", wearCount: 5, lastWornDate: daysAgo(120), createdAt: daysAgo(450), tags: ["knit", "warm"]),
            Garment(name: "Puffer jacket", category: .outerwear, colorHex: "#1F2A44", season: .winter, imageFilename: "", wearCount: 0, createdAt: daysAgo(400), tags: ["warm", "padded"]),
            Garment(name: "Black trousers", category: .bottoms, colorHex: "#373A3C", season: .allSeason, imageFilename: "", wearCount: 18, lastWornDate: daysAgo(5), createdAt: daysAgo(520), tags: ["tailored", "work"]),
            Garment(name: "Relaxed denim", category: .bottoms, colorHex: "#7794AC", season: .allSeason, imageFilename: "", wearCount: 15, lastWornDate: daysAgo(9), createdAt: daysAgo(480), tags: ["denim", "casual"]),
            Garment(name: "Straight blue jeans", category: .bottoms, colorHex: "#6F8DB0", season: .allSeason, imageFilename: "", wearCount: 1, lastWornDate: daysAgo(220), createdAt: daysAgo(430), tags: ["denim"]),
            Garment(name: "Canvas sneakers", category: .shoes, colorHex: "#E7E1D4", season: .allSeason, imageFilename: "", wearCount: 31, lastWornDate: daysAgo(2), createdAt: daysAgo(350), tags: ["everyday"]),
            Garment(name: "Leather loafers", category: .shoes, colorHex: "#80563D", season: .allSeason, imageFilename: "", wearCount: 7, lastWornDate: daysAgo(60), createdAt: daysAgo(410), tags: ["formal"]),
            Garment(name: "Winter boots", category: .shoes, colorHex: "#3B2A22", season: .winter, imageFilename: "", wearCount: 1, lastWornDate: daysAgo(150), createdAt: daysAgo(390), tags: ["warm"]),
            Garment(name: "Silver watch", category: .accessories, colorHex: "#9DA4A7", season: .allSeason, imageFilename: "", wearCount: 42, lastWornDate: daysAgo(1), createdAt: daysAgo(700), tags: ["daily"]),
            Garment(name: "Crossbody bag", category: .bags, colorHex: "#8C6248", season: .allSeason, imageFilename: "", wearCount: 11, lastWornDate: daysAgo(12), createdAt: daysAgo(330), tags: ["leather"]),
            Garment(name: "Weekend tote", category: .bags, colorHex: "#C1A17B", season: .summer, imageFilename: "", wearCount: 3, lastWornDate: daysAgo(95), createdAt: daysAgo(280), tags: ["canvas"]),
            Garment(name: "Knit dress", category: .dresses, colorHex: "#A96665", season: .winter, imageFilename: "", wearCount: 0, createdAt: daysAgo(330), tags: ["knit", "occasion"]),
            Garment(name: "Floral sundress", category: .dresses, colorHex: "#E3A6B1", season: .summer, imageFilename: "", wearCount: 2, lastWornDate: daysAgo(200), createdAt: daysAgo(360), tags: ["floral", "light"])
        ]
    }

    @MainActor
    static func seed(into context: ModelContext) {
        for garment in makeGarments() { context.insert(garment) }
        try? context.save()
    }

    @MainActor
    static var previewContainer: ModelContainer = {
        let schema = Schema([Garment.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        for garment in makeGarments() { container.mainContext.insert(garment) }
        return container
    }()
}
