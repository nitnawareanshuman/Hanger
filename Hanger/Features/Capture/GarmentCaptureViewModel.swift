import Foundation
import SwiftUI
import SwiftData
import UIKit

@MainActor
@Observable
final class GarmentCaptureViewModel {
    private static let placeholderName = "New garment"

    var capturedImage: UIImage?
    var processedImage: UIImage?
    var dominantColorHex = "#8A8A8A"
    var dominantColorName = "gray"
    var garmentName = ""
    var selectedCategory: GarmentCategory = .tops
    var selectedSeason: Season = .allSeason
    var styleTags: [String] = []
    var isProcessing = false
    var isCategorizing = false
    var aiFilled = false
    var aiNotice: String?
    var errorMessage: String?
    var didSave = false
    var hasTransparentBackground = false

    var previewImage: UIImage? { processedImage ?? capturedImage }

    private let processor = GarmentImageProcessor()
    private var processingTask: Task<Void, Never>?
    private var aiTask: Task<Void, Never>?
    private var aiToken = UUID()

    func handleCapture(_ image: UIImage) {
        processingTask?.cancel()
        capturedImage = image
        processedImage = nil
        hasTransparentBackground = false
        errorMessage = nil
        didSave = false
        isProcessing = true
        garmentName = Self.placeholderName
        styleTags = []
        aiFilled = false
        aiNotice = nil

        // Quick colour estimate so the review screen never shows a stale default
        // while segmentation runs in the background.
        if let color = processor.dominantColor(in: image) {
            dominantColorHex = color.hex
            dominantColorName = color.name
        }

        startCategorization(for: image)

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
                // Non-fatal: the original photo is still saved as a fallback.
                processedImage = nil
                hasTransparentBackground = false
                errorMessage = "Couldn't remove the background: \(error.localizedDescription) You can still save the original photo."
            }
        }
    }

    func retake() {
        processingTask?.cancel()
        processingTask = nil
        aiTask?.cancel()
        aiTask = nil
        aiToken = UUID()
        capturedImage = nil
        processedImage = nil
        hasTransparentBackground = false
        errorMessage = nil
        aiNotice = nil
        aiFilled = false
        isProcessing = false
        isCategorizing = false
        didSave = false
        garmentName = ""
        styleTags = []
        selectedCategory = .tops
        selectedSeason = .allSeason
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

            var tags = [dominantColorName]
            for tag in styleTags where !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                tags.append(tag)
            }

            let garment = Garment(
                name: title.isEmpty ? Self.placeholderName : title,
                category: selectedCategory,
                colorHex: dominantColorHex,
                season: selectedSeason,
                imageFilename: filename,
                wearCount: 0,
                tags: tags
            )
            context.insert(garment)
            try context.save()
            aiTask?.cancel()
            aiToken = UUID()
            didSave = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            if let savedFilename { GarmentImageStore.delete(filename: savedFilename) }
            errorMessage = "Couldn't save this garment. \(error.localizedDescription)"
        }
    }

    // MARK: - AI auto-categorisation

    /// Runs in parallel with background removal. Uses the original (downscaled) photo,
    /// because a transparent PNG would be flattened to black when encoded as JPEG.
    private func startCategorization(for image: UIImage) {
        aiTask?.cancel()
        let token = UUID()
        aiToken = token
        isCategorizing = true

        aiTask = Task { [weak self] in
            let small = image.resized(maxDimension: 768)
            do {
                let result = try await OpenAIWardrobeService.shared.categorize(image: small)
                guard let self, self.aiToken == token else { return }
                self.apply(result)
            } catch {
                guard let self, self.aiToken == token else { return }
                if error is CancellationError { return }
                if let aiError = error as? WardrobeAIError, case .missingAPIKey = aiError {
                    self.aiNotice = "AI auto-fill is off (no API key). Choose the details yourself."
                } else {
                    self.aiNotice = "AI auto-fill unavailable. You can edit the details manually."
                }
            }
            if let self, self.aiToken == token { self.isCategorizing = false }
        }
    }

    private func apply(_ result: GarmentClassification) {
        let current = garmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty || current == Self.placeholderName {
            garmentName = result.name
        }
        selectedCategory = result.appCategory
        selectedSeason = result.appSeason
        styleTags = result.style_tags
        aiFilled = true
    }
}
