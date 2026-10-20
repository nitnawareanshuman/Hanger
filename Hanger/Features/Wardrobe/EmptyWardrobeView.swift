import SwiftUI

struct EmptyWardrobeView: View {
    /// When provided, shows a "load sample wardrobe" shortcut (handy for demos and reviewers).
    var onLoadSample: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hanger")
                .font(.system(size: 36))
                .foregroundStyle(Color.wardrobeAccent)

            Text("Your wardrobe is waiting")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("Tap the camera to capture your first garment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let onLoadSample {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onLoadSample()
                } label: {
                    Label("Load sample wardrobe", systemImage: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.wardrobeInk, in: Capsule())
                        .foregroundStyle(Color.wardrobeBackground)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(Color.wardrobeChip, in: RoundedRectangle(cornerRadius: 22))
    }
}
