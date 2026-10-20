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
    var dominantColorName = "gray"
    var garmentName = ""
    var selectedCategory: GarmentCategory = .tops
    var selectedSeason: Season = .allSeason
    var isProcessing = false
    var errorMessage: String?
    var didSave = false
    var hasTransparentBackground = false

    var previewImage: UIImage? { processedImage ?? capturedImage }

    private let processor = GarmentImageProcessor()
    private var processingTask: Task<Void, Never>?

    func handleCapture(_ image: UIImage) {
        processingTask?.cancel()
        capturedImage = image
        processedImage = nil
        hasTransparentBackground = false
        errorMessage = nil
        didSave = false
        isProcessing = true

        // Calculate a useful color immediately, so the review screen is never left
        // showing a stale default while segmentation is in progress.
        if let color = processor.dominantColor(in: image) {
            dominantColorHex = color.hex
            dominantColorName = color.name
        }
        if garmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            garmentName = "New garment"
        }

        processingTask = Task {
            defer { isProcessing = false }
            do {
                let result = try await processor.process(image)
                try Task.checkCancellation()
                processedImage = result.image
                dominantColorHex = result.dominantColorHex
                dominantColorName = result.dominantColorName
                hasTransparentBackground = true
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                // Important: processing failure is non-fatal. The original image
                // remains available and save() deliberately persists it as fallback.
                processedImage = nil
                hasTransparentBackground = false
                if let color = processor.dominantColor(in: image) {
                    dominantColorHex = color.hex
                    dominantColorName = color.name
                }
                errorMessage = "Couldn't remove the background: \(error.localizedDescription) You can still save the original photo."
            }
        }
    }

    func retake() {
        processingTask?.cancel()
        processingTask = nil
        capturedImage = nil
        processedImage = nil
        hasTransparentBackground = false
        errorMessage = nil
        isProcessing = false
        didSave = false
    }

    func save(context: ModelContext) {
        guard !isProcessing, let image = processedImage ?? capturedImage else {
            errorMessage = isProcessing
                ? "Wait for image processing to finish."
                : "Capture or choose a garment first."
            return
        }

        var savedFilename: String?
        do {
            let filename = try GarmentImageStore.save(image)
            savedFilename = filename
            let title = garmentName.trimmingCharacters(in: .whitespacesAndNewlines)
            let garment = Garment(
                name: title.isEmpty ? "New garment" : title,
                category: selectedCategory,
                colorHex: dominantColorHex,
                season: selectedSeason,
                imageFilename: filename,
                wearCount: 0,
                tags: [dominantColorName]
            )
            context.insert(garment)
            try context.save()
            didSave = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            if let savedFilename { GarmentImageStore.delete(filename: savedFilename) }
            errorMessage = "Couldn't save this garment. \(error.localizedDescription)"
        }
    }
    
    func autoCategorize(_ image: UIImage) async {
        do {
            let result = try await OpenAIWardrobeService.shared.categorize(image: image)
            garmentName = result.name
            selectedCategory = result.appCategory
            selectedSeason = result.appSeason
            // If you add a styleTags property to the view model, assign result.style_tags here.
        } catch {
            errorMessage = "Auto-categorization unavailable. You can edit this garment manually."
        }
    }
}
