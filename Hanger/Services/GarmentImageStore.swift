import Foundation
import UIKit

enum GarmentImageStore {
    static func save(_ image: UIImage) throws -> String {
        guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let directory = try imageDirectory()
        let filename = "\(UUID().uuidString).png"
        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
        return filename
    }

    static func load(filename: String) -> UIImage? {
        guard let directory = try? imageDirectory() else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    static func delete(filename: String) {
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
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }
}
