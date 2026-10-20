import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InsightsViewModel {
    var recommendations: [WardrobeAIRecommendation] = []
    var summary = ""
    var isLoading = false
    var isFallback = false
    var errorMessage: String?

    private var dismissedIDs = Set<String>()
    private let heuristic = WardrobeRecommendationEngine()

    func load(garments: [Garment]) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let items = garments.map { garment in
            WardrobeAIItem(
                id: garment.id.uuidString,
                category: garment.category.rawValue,
                color: garment.colorHex,
                season: garment.season.rawValue,
                wearCount: max(0, garment.wearCount),
                daysSinceLastWorn: max(
                    0,
                    Calendar.current.dateComponents(
                        [.day],
                        from: garment.lastWornDate ?? garment.createdAt,
                        to: .now
                    ).day ?? 0
                )
            )
        }

        do {
            let response = try await OpenAIWardrobeService.shared.recommend(for: items)
            recommendations = response.recommendations.filter { !dismissedIDs.contains($0.garmentId) }
            summary = response.summary
            isFallback = false
        } catch {
            let response = heuristic.fallback(for: items)
            recommendations = response.recommendations.filter { !dismissedIDs.contains($0.garmentId) }
            summary = response.summary
            isFallback = true
            errorMessage = error.localizedDescription
        }
    }

    func dismiss(_ recommendation: WardrobeAIRecommendation) {
        dismissedIDs.insert(recommendation.garmentId)
        recommendations.removeAll { $0.garmentId == recommendation.garmentId }
    }

    func accept(
        _ recommendation: WardrobeAIRecommendation,
        garments: [Garment],
        context: ModelContext
    ) {
        guard let garment = garments.first(where: {
            $0.id.uuidString == recommendation.garmentId
        }) else {
            dismiss(recommendation)
            return
        }

        if recommendation.action == .donate {
            garment.isArchived = true
        }

        do {
            try context.save()
            dismiss(recommendation)
        } catch {
            errorMessage = "Couldn't save your change: \(error.localizedDescription)"
        }
    }
}
