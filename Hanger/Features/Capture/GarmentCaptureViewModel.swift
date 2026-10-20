import Foundation
import SwiftUI
import SwiftData
import UIKit

@MainActor
@Observable
final class GarmentCaptureViewModel {
    var capturedImage: UIImage?
    var processedImage: UIImage?
    var dominantColorHex = "#8A8A8A"
    var garmentName = ""
    var selectedCategory: GarmentCategory = .tops
    var selectedSeason: Season = .allSeason
    var isProcessing = false
    var errorMessage: String?
    var didSave = false

    private let processor = GarmentImageProcessor()

    func handleCapture(_ image: UIImage) {
        capturedImage = image
        processedImage = nil
        errorMessage = nil
        didSave = false
        Task {
            isProcessing = true
            defer { isProcessing = false }
            do {
                let result = try await processor.process(image)
                processedImage = result.image
                dominantColorHex = result.dominantColorHex
                if garmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    garmentName = "New garment"
                }
            } catch {
                // Keep the original capture available if masking fails.
                processedImage = image
                dominantColorHex = processor.dominantColorHex(in: image) ?? "#8A8A8A"
                errorMessage = "Background removal wasn't available for this photo. You can still save the original image."
            }
        }
    }

    func save(context: ModelContext) {
        guard let image = processedImage ?? capturedImage else {
            errorMessage = "Capture a garment first."
            return
        }
        do {
            let filename = try GarmentImageStore.save(image)
            let title = garmentName.trimmingCharacters(in: .whitespacesAndNewlines)
            let garment = Garment(
                name: title.isEmpty ? "New garment" : title,
                category: selectedCategory,
                colorHex: dominantColorHex,
                season: selectedSeason,
                imageFilename: filename,
                wearCount: 0,
                tags: []
            )
            context.insert(garment)
            try context.save()
            didSave = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Couldn't save this garment. \(error.localizedDescription)"
        }
    }
}
