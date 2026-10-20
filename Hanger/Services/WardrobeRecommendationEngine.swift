import Foundation

/// Rule-based fallback used when the AI call fails or no API key is configured.
/// Covers the same four themes as the AI prompt: duplicates, long-unused items,
/// seasonal mismatch and low-wear pieces worth re-styling.
struct WardrobeRecommendationEngine {
    func fallback(for items: [WardrobeAIItem], now: Date = .now) -> WardrobeRecommendationsResponse {
        var picked: [String: WardrobeAIRecommendation] = [:]
        var order: [String] = []

        func add(_ item: WardrobeAIItem, _ action: ClutterAction, _ reason: String, _ confidence: Double) {
            guard picked[item.id] == nil else { return }
            picked[item.id] = WardrobeAIRecommendation(
                garmentId: item.id, action: action, reason: reason, confidence: confidence
            )
            order.append(item.id)
        }

        // 1. Near-duplicates: same category and colour, keep the most worn.
        let groups = Dictionary(grouping: items) { "\($0.category)|\($0.color)" }
        for key in groups.keys.sorted() {
            guard let group = groups[key], group.count > 1 else { continue }
            let ranked = group.sorted { $0.wearCount > $1.wearCount }
            for item in ranked.dropFirst() where item.wearCount <= 3 || item.daysSinceLastWorn >= 120 {
                add(item, .donate,
                    "Similar to \(ranked[0].name), which you wear far more often. Consider letting this one go.",
                    0.7)
            }
        }

        // 2. Barely worn and long untouched.
        for item in items.sorted(by: { $0.daysSinceLastWorn > $1.daysSinceLastWorn })
        where item.wearCount <= 1 && item.daysSinceLastWorn >= 180 {
            add(item, .donate,
                "Worn \(item.wearCount) time(s) and untouched for about \(item.daysSinceLastWorn) days. Review whether it still suits you.",
                0.68)
        }

        // 3. Seasonal mismatch.
        let current = Self.currentSeason(now)
        for item in items where item.season != Season.allSeason.rawValue {
            if item.season != current.rawValue, item.daysSinceLastWorn >= 90 {
                add(item, .rotate,
                    "\(item.name) is a \(item.season) piece. Store it away now and bring it back when the season returns.",
                    0.6)
            } else if item.season == current.rawValue, item.daysSinceLastWorn >= 45 {
                add(item, .rotate,
                    "\(item.name) suits the current season but hasn't been worn for \(item.daysSinceLastWorn) days. Bring it into rotation.",
                    0.62)
            }
        }

        // 4. Low wear, worth re-styling before deciding.
        for item in items where item.wearCount < 3 {
            add(item, .pair,
                "Only worn \(item.wearCount) time(s). Try styling \(item.name) with a different category before deciding.",
                0.55)
        }

        // 5. Balance the list with clear favourites.
        for item in items.sorted(by: { $0.wearCount > $1.wearCount }).prefix(3) where item.wearCount >= 10 {
            add(item, .keep, "Worn \(item.wearCount) times, so this is a proven favourite.", 0.85)
        }

        let recommendations = order.prefix(12).compactMap { picked[$0] }
        return WardrobeRecommendationsResponse(
            recommendations: Array(recommendations),
            summary: "These suggestions use your wear history and simple rules because AI recommendations were unavailable."
        )
    }

    /// Northern-hemisphere meteorological seasons; good enough for a rule-based fallback.
    static func currentSeason(_ date: Date) -> Season {
        switch Calendar.current.component(.month, from: date) {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
    }
}
