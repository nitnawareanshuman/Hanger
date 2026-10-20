import SwiftUI

struct RecommendationCardView: View {
    let recommendation: WardrobeAIRecommendation
    let garment: Garment?
    let onDismiss: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                thumbnail
                    .frame(width: 66, height: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text(garment?.name ?? "Wardrobe item").font(.headline)
                    Label(recommendation.action.label, systemImage: recommendation.action.symbol)
                        .font(.caption.bold())
                        .foregroundStyle(Color.wardrobeAccent)
                    Text(recommendation.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack {
                Text("Confidence").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: recommendation.confidence)
                    .tint(Color.wardrobeAccent)
                    .frame(maxWidth: 90)
                Text("\(Int(recommendation.confidence * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("Dismiss").frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button(action: onAccept) {
                    Text(recommendation.action == .donate ? "Accept & archive" : "Got it")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.wardrobeInk)
            }
        }
        .padding(16)
        .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let garment {
            GarmentImageView(garment: garment, padding: 4)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.16))
                Image(systemName: "tshirt").font(.system(size: 27)).foregroundStyle(Color.wardrobeInk)
            }
        }
    }
}

private extension ClutterAction {
    var label: String {
        switch self {
        case .donate: "Consider donating"
        case .keep: "Keep"
        case .pair: "Try new pairings"
        case .rotate: "Rotate seasonally"
        }
    }

    var symbol: String {
        switch self {
        case .donate: "gift"
        case .keep: "heart"
        case .pair: "square.on.square"
        case .rotate: "arrow.triangle.2.circlepath"
        }
    }
}
