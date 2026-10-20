import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

struct GarmentImageProcessingResult {
    let image: UIImage
    let dominantColorHex: String
}

enum GarmentImageProcessingError: LocalizedError {
    case invalidImage
    case maskFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: "This image couldn't be processed."
        case .maskFailed: "Vision couldn't isolate a foreground object in this image."
        }
    }
}

final class GarmentImageProcessor {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func process(_ image: UIImage) async throws -> GarmentImageProcessingResult {
        guard let cgImage = image.cgImage else { throw GarmentImageProcessingError.invalidImage }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard let observation = request.results?.first else {
            throw GarmentImageProcessingError.maskFailed
        }
        let maskBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: handler
        )
        let mask = CIImage(cvPixelBuffer: maskBuffer)
        let source = CIImage(cgImage: cgImage)

        // Scale/crop the mask to the original source dimensions before compositing.
        let scaledMask = mask.transformed(by: CGAffineTransform(
            scaleX: source.extent.width / mask.extent.width,
            y: source.extent.height / mask.extent.height
        ))
        let alignedMask = scaledMask.transformed(by: CGAffineTransform(
            translationX: source.extent.minX - scaledMask.extent.minX,
            y: source.extent.minY - scaledMask.extent.minY
        ))
        let clear = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: source.extent)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = source
        blend.backgroundImage = clear
        blend.maskImage = alignedMask
        guard let output = blend.outputImage,
              let cgOutput = ciContext.createCGImage(output, from: source.extent) else {
            throw GarmentImageProcessingError.maskFailed
        }

        let cutout = UIImage(cgImage: cgOutput, scale: image.scale, orientation: image.imageOrientation)
        return GarmentImageProcessingResult(
            image: cutout,
            dominantColorHex: dominantColorHex(in: image) ?? "#8A8A8A"
        )
    }

    func dominantColorHex(in image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let input = CIImage(cgImage: cgImage)
        let extent = input.extent
        let average = CIFilter.areaAverage()
        average.inputImage = input
        average.extent = extent
        guard let output = average.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return String(format: "#%02X%02X%02X", pixel[0], pixel[1], pixel[2])
    }
}
