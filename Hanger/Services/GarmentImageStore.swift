import Foundation
import UIKit

enum GarmentImageStore {
    /// Decoded images are cached so scrolling and the hanger swing animation never hit the disk.
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        return cache
    }()

    static func save(_ image: UIImage) throws -> String {
        // Camera frames are ~12 MP; a wardrobe thumbnail never needs that.
        let prepared = image.resized(maxDimension: 1400)
        guard let data = prepared.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let directory = try imageDirectory()
        let filename = "\(UUID().uuidString).png"
        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
        cache.setObject(prepared, forKey: filename as NSString)
        return filename
    }

    static func load(filename: String) -> UIImage? {
        guard !filename.isEmpty else { return nil }
        if let cached = cache.object(forKey: filename as NSString) { return cached }
        guard let directory = try? imageDirectory(),
              let image = UIImage(contentsOfFile: directory.appendingPathComponent(filename).path) else {
            return nil
        }
        cache.setObject(image, forKey: filename as NSString)
        return image
    }

    static func delete(filename: String) {
        guard !filename.isEmpty else { return }
        cache.removeObject(forKey: filename as NSString)
        guard let directory = try? imageDirectory() else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    private static func imageDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("GarmentImages", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
