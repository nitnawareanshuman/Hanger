import SwiftUI

struct CategoryFilterView: View {
    @Binding var selection: GarmentCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", symbol: "square.grid.2x2", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(GarmentCategory.allCases) { category in
                    categoryChip(title: category.title, symbol: category.symbolName, isSelected: selection == category) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryChip(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background { Capsule().fill(isSelected ? Color.wardrobeInk : Color.wardrobeChip) }
        }
        .buttonStyle(.plain)
    }
}

private extension GarmentCategory {
    var symbolName: String {
        switch self {
        case .tops: "tshirt"
        case .bottoms: "figure.stand"
        case .dresses: "hanger"
        case .outerwear: "cloud"
        case .shoes: "shoe"
        case .accessories: "watch"
        case .bags: "bag"
        }
    }
}
