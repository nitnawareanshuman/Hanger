import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

enum BackgroundRemovalError: LocalizedError {
    case invalidImage
    case noForeground
    case outputCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "This photo couldn't be decoded."
        case .noForeground:
            return "No clear foreground subject was detected. Try a plain background and good lighting."
        case .outputCreationFailed:
            return "The transparent cut-out couldn't be rendered."
        }
    }
}

/// Uses the iOS 17 Vision foreground-instance mask API and trims transparent margins.
struct BackgroundRemovalService {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else { throw BackgroundRemovalError.invalidImage }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
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

        // Preserve a little transparent padding rather than cutting into the garment.
        let margin = max(8, min(bounds.width, bounds.height) * 0.035)
        let crop = bounds.insetBy(dx: -margin, dy: -margin).intersection(source.extent)
        guard !crop.isNull, !crop.isEmpty,
              let croppedCG = context.createCGImage(composited, from: crop) else {
            throw BackgroundRemovalError.outputCreationFailed
        }

        return UIImage(cgImage: croppedCG, scale: image.scale, orientation: .up)
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
        // Convert the top-origin pixel scan to Core Graphics' image-coordinate rectangle.
        return CGRect(
            x: minX,
            y: height - maxY - 1,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}
