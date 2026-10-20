import SwiftUI

struct WardrobeShelfView: View {
    let title: String
    let subtitle: String
    let garments: [Garment]
    let compact: Bool
    let onSelect: (Garment) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text(subtitle.uppercased()).font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(.secondary)
            }
            if garments.isEmpty {
                EmptyShelfView().frame(height: 94)
            } else {
                LazyVGrid(columns: columns, spacing: 13) {
                    ForEach(garments) { garment in
                        GarmentCardView(garment: garment, isCompact: compact) { onSelect(garment) }
                            .draggable(garment.id.uuidString)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.wardrobeInterior.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.wardrobeWoodHighlight.opacity(0.4), lineWidth: 1))
    }
}

private struct EmptyShelfView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "hanger").font(.title3).foregroundStyle(.secondary)
            Text("Nothing here yet").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
    }
}
