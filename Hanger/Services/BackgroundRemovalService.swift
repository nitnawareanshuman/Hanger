import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UIKit
import Vision

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case noForeground
    case outputCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "This photo couldn't be decoded. Try another photo."
        case .noForeground:
            return "Vision couldn't isolate the garment. Try a plain, contrasting background and good lighting."
        case .outputCreationFailed:
            return "The transparent cut-out couldn't be rendered. You can still save the original photo."
        }
    }
}

/// Runs Vision foreground segmentation on an orientation-normalized image.
/// Vision does not infer UIImage orientation from a cgImage, so normalize first.
struct BackgroundRemovalService {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let normalized = image.normalizedForVision(),
              let cgImage = normalized.cgImage else {
            throw BackgroundRemovalError.invalidImage
        }

        // The Vision request is synchronous. It executes inside this async service and
        // is never called directly by the view body.
        let request = VNGenerateForegroundInstanceMaskRequest()
        request.usesCPUOnly = false
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            throw BackgroundRemovalError.noForeground
        }

        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )

        let source = CIImage(cgImage: cgImage)
        let mask = CIImage(cvPixelBuffer: maskBuffer)
        let resizedMask = mask.transformed(by: CGAffineTransform(
            scaleX: source.extent.width / mask.extent.width,
            y: source.extent.height / mask.extent.height
        ))
        let alignedMask = resizedMask.transformed(by: CGAffineTransform(
            translationX: source.extent.minX - resizedMask.extent.minX,
            y: source.extent.minY - resizedMask.extent.minY
        ))

        let clear = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: source.extent)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = source
        blend.backgroundImage = clear
        blend.maskImage = alignedMask

        guard let composited = blend.outputImage,
              let cutoutCG = context.createCGImage(composited, from: source.extent),
              let bounds = alphaBounds(of: cutoutCG) else {
            throw BackgroundRemovalError.noForeground
        }

        let margin = max(8, min(bounds.width, bounds.height) * 0.035)
        let crop = bounds.insetBy(dx: -margin, dy: -margin).intersection(source.extent)
        guard !crop.isNull, !crop.isEmpty,
              let croppedCG = context.createCGImage(composited, from: crop) else {
            throw BackgroundRemovalError.outputCreationFailed
        }

        return UIImage(cgImage: croppedCG, scale: normalized.scale, orientation: .up)
    }

    private func alphaBounds(of image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        let rowBytes = width * 4
        var bytes = [UInt8](repeating: 0, count: height * rowBytes)

        guard let bitmap = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        bitmap.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where bytes[y * rowBytes + x * 4 + 3] > 12 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(
            x: minX,
            y: height - maxY - 1,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}

private extension UIImage {
    /// Draws the image into an upright bitmap so Vision sees the same orientation
    /// shown to the user, whether it came from the camera or Photos.
    func normalizedForVision() -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
