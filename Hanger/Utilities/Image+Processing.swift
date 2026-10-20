import UIKit

extension UIImage {
    /// Returns an upright copy no larger than `maxDimension` on its longest side.
    /// Keeps Vision, disk storage and network uploads fast and memory-friendly.
    nonisolated func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
