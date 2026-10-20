import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class WardrobeViewModel {
    var selectedCategory: GarmentCategory? = nil
    var selectedGarmentID: UUID? = nil
    var showCapturePlaceholder = false
    var searchText = ""

    func filtered(_ garments: [Garment]) -> [Garment] {
        garments.filter { garment in
            let matchesCategory = selectedCategory == nil || garment.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                garment.name.localizedCaseInsensitiveContains(searchText) ||
                garment.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesCategory && matchesSearch
        }
    }

    func markAsWorn(_ garment: Garment) {
        garment.wearCount += 1
        garment.lastWornDate = .now
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func select(_ garment: Garment) {
        selectedGarmentID = garment.id
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
