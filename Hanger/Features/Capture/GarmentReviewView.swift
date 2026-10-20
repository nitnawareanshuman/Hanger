import SwiftUI
import UIKit

/// Reusable transparency preview for future capture-flow extraction.
struct GarmentReviewView: View {
    let image: UIImage
    let isProcessing: Bool
    let errorMessage: String?
    let dominantColorHex: String
    let dominantColorName: String
    let onRetake: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Checkerboard()
                Image(uiImage: image).resizable().scaledToFit().padding(18)
                if isProcessing {
                    VStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Cleaning up the garment…").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            HStack(spacing: 12) {
                Circle().fill(Color(hex: dominantColorHex)).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(dominantColorName.capitalized).font(.headline)
                    Text(dominantColorHex).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                Button(action: onConfirm) {
                    Label("Confirm", systemImage: "checkmark")
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.wardrobeAccent)
                .disabled(isProcessing)
            }
        }
        .padding(18)
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let side: CGFloat = 16
            for row in 0..<Int(ceil(size.height / side)) {
                for column in 0..<Int(ceil(size.width / side)) {
                    let rect = CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
                    context.fill(Path(rect), with: .color((row + column).isMultiple(of: 2) ? .gray.opacity(0.20) : .gray.opacity(0.08)))
                }
            }
        }
    }
}
