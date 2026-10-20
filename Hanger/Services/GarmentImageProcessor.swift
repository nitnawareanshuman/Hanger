import UIKit

struct GarmentImageProcessingResult {
    let image: UIImage
    let dominantColorHex: String
    let dominantColorName: String
}

enum GarmentImageProcessingError: LocalizedError {
    case invalidImage
    var errorDescription: String? { "This image couldn't be processed." }
}

struct GarmentImageProcessor {
    private let backgroundRemoval = BackgroundRemovalService()

    func process(_ image: UIImage) async throws -> GarmentImageProcessingResult {
        let cutout = try await backgroundRemoval.removeBackground(from: image)
        guard let color = ColorAnalysisService.dominantColor(in: cutout) else {
            throw GarmentImageProcessingError.invalidImage
        }
        return GarmentImageProcessingResult(
            image: cutout,
            dominantColorHex: color.hex,
            dominantColorName: color.name
        )
    }

    func dominantColor(in image: UIImage) -> DominantColor? {
        ColorAnalysisService.dominantColor(in: image)
    }
}
