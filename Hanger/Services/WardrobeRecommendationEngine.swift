import Foundation

struct WardrobeRecommendationEngine {
    func fallback(for items: [WardrobeAIItem]) -> WardrobeRecommendationsResponse {
        let sorted = items.sorted { score($0) > score($1) }

        let recommendations = sorted.prefix(12).map { item -> WardrobeAIRecommendation in
            let action: ClutterAction
            let reason: String
            let confidence: Double

            if item.wearCount <= 1 && item.daysSinceLastWorn >= 180 {
                action = .donate
                reason = "This item has very low wear and has been inactive for a while. Review whether it still suits your needs."
                confidence = 0.68
            } else if item.season != "allSeason" && item.daysSinceLastWorn >= 90 {
                action = .rotate
                reason = "Consider bringing this seasonal item back into rotation when its season is appropriate."
                confidence = 0.62
            } else if item.wearCount < 3 {
                action = .pair
                reason = "Try styling this item with pieces from another category before deciding to remove it."
                confidence = 0.55
            } else {
                action = .keep
                reason = "There is not enough evidence to suggest removing this item from your wardrobe."
                confidence = 0.78
            }

            return WardrobeAIRecommendation(
                garmentId: item.id,
                action: action,
                reason: reason,
                confidence: confidence
            )
        }

        return WardrobeRecommendationsResponse(
            recommendations: Array(recommendations),
            summary: "These suggestions use wear history and simple rules because AI recommendations were unavailable."
        )
    }

    private func score(_ item: WardrobeAIItem) -> Int {
        var value = 0
        if item.wearCount <= 1 { value += 2 }
        if item.daysSinceLastWorn >= 180 { value += 3 }
        else if item.daysSinceLastWorn >= 90 { value += 1 }
        return value
    }
}
