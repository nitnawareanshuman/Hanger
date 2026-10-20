import SwiftUI

struct GarmentCardView: View {
    let garment: Garment
    var isCompact = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let image = GarmentImageStore.load(
                        filename: garment.imageFilename
                    ) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    } else {
                        GarmentIllustration(garment: garment)
                    }
                }
                .frame(height: isCompact ? 112 : 142)
                .frame(maxWidth: .infinity)
                .background(Color(hex: garment.colorHex).opacity(0.12))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 15,
                        style: .continuous
                    )
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text(garment.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text("\(garment.wearCount) wears")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(garment.name), \(garment.wearCount) wears")
    }
}

struct GarmentIllustration: View {
    let garment: Garment

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: garment.colorHex).opacity(0.12), Color(hex: garment.colorHex).opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: garment.category.illustrationSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(LinearGradient(colors: [Color(hex: garment.colorHex), Color(hex: garment.colorHex).opacity(0.68)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .shadow(color: Color(hex: garment.colorHex).opacity(0.18), radius: 8, y: 4)
        }
    }
}

extension GarmentCategory {
    var illustrationSymbol: String {
        switch self {
        case .tops: "tshirt.fill"
        case .bottoms: "figure.stand"
        case .dresses: "hanger"
        case .outerwear: "jacket.fill"
        case .shoes: "shoe.fill"
        case .accessories: "watch"
        case .bags: "bag.fill"
        }
    }
}
