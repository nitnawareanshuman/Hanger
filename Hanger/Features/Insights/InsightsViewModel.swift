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
    private var loadedIDs = Set<UUID>()
    private let heuristic = WardrobeRecommendationEngine()
    private let maxItemsSent = 60

    /// Reload when nothing is loaded yet or garments were added since the last analysis.
    func needsRefresh(for garments: [Garment]) -> Bool {
        recommendations.isEmpty || !Set(garments.map(\.id)).isSubset(of: loadedIDs)
    }

    func load(garments: [Garment]) async {
        guard !isLoading else { return }
        guard !garments.isEmpty else {
            recommendations = []
            summary = ""
            isFallback = false
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let items = garments.prefix(maxItemsSent).map { garment in
            WardrobeAIItem(
                id: garment.id.uuidString,
                name: garment.name,
                category: garment.category.rawValue,
                color: ColorAnalysisService.name(forHex: garment.colorHex),
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
            let response = try await OpenAIWardrobeService.shared.recommend(for: Array(items))
            recommendations = response.recommendations.filter { !dismissedIDs.contains($0.garmentId) }
            summary = response.summary
            isFallback = false
            loadedIDs = Set(garments.map(\.id))
        } catch {
            // Leaving the tab cancels the request; that is not a failure worth reporting.
            if error is CancellationError || (error as? URLError)?.code == .cancelled { return }
            let response = heuristic.fallback(for: Array(items))
            recommendations = response.recommendations.filter { !dismissedIDs.contains($0.garmentId) }
            summary = response.summary
            isFallback = true
            errorMessage = error.localizedDescription
            loadedIDs = Set(garments.map(\.id))
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss(recommendation)
        } catch {
            errorMessage = "Couldn't save your change: \(error.localizedDescription)"
        }
    }

    func restore(_ garment: Garment, context: ModelContext) {
        garment.isArchived = false
        try? context.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
