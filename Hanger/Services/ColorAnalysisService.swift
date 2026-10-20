import CoreGraphics
import UIKit

nonisolated struct DominantColor: Equatable {
    let hex: String
    let name: String
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var uiColor: UIColor {
        UIColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }
}

/// Quantizes visible pixels into RGB histogram buckets. Fully transparent pixels are ignored.
nonisolated enum ColorAnalysisService {
    static func dominantColor(in image: UIImage) -> DominantColor? {
        guard let cgImage = image.cgImage else { return nil }

        let width = min(cgImage.width, 256)
        let height = max(1, Int(Double(cgImage.height) * Double(width) / Double(cgImage.width)))
        let rowBytes = width * 4
        var pixels = [UInt8](repeating: 0, count: height * rowBytes)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var histogram: [Int: Int] = [:]
        var sums: [Int: (r: Int, g: Int, b: Int, count: Int)] = [:]

        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Int(pixels[offset + 3])
            guard alpha > 24 else { continue }

            // Undo premultiplication so semi-transparent edge colors remain useful.
            let r = min(255, Int(pixels[offset]) * 255 / max(alpha, 1))
            let g = min(255, Int(pixels[offset + 1]) * 255 / max(alpha, 1))
            let b = min(255, Int(pixels[offset + 2]) * 255 / max(alpha, 1))

            // Five bits per channel produces 32,768 possible quantization buckets.
            let key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)
            histogram[key, default: 0] += 1
            var bucket = sums[key] ?? (0, 0, 0, 0)
            bucket.r += r
            bucket.g += g
            bucket.b += b
            bucket.count += 1
            sums[key] = bucket
        }

        guard let key = histogram.max(by: { $0.value < $1.value })?.key,
              let bucket = sums[key],
              bucket.count > 0 else { return nil }

        let r = UInt8(bucket.r / bucket.count)
        let g = UInt8(bucket.g / bucket.count)
        let b = UInt8(bucket.b / bucket.count)

        return DominantColor(
            hex: String(format: "#%02X%02X%02X", r, g, b),
            name: name(forRed: r, green: g, blue: b),
            red: r,
            green: g,
            blue: b
        )
    }

    /// Human colour name for a stored hex string (used when talking to the AI and for tags).
    static func name(forHex hex: String) -> String {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count >= 6, let value = UInt32(cleaned.prefix(6), radix: 16) else { return "gray" }
        return name(
            forRed: UInt8((value >> 16) & 0xFF),
            green: UInt8((value >> 8) & 0xFF),
            blue: UInt8(value & 0xFF)
        )
    }

    private static func name(forRed r: UInt8, green g: UInt8, blue b: UInt8) -> String {
        let rf = Double(r) / 255
        let gf = Double(g) / 255
        let bf = Double(b) / 255
        let maximum = max(rf, gf, bf)
        let minimum = min(rf, gf, bf)
        let delta = maximum - minimum
        let brightness = maximum
        let saturation = maximum == 0 ? 0 : delta / maximum

        if brightness < 0.12 { return "black" }
        if brightness > 0.94 && saturation < 0.12 { return "white" }

        if saturation < 0.12 {
            if brightness < 0.30 { return "charcoal" }
            if brightness < 0.55 { return "gray" }
            if brightness < 0.78 { return "silver" }
            return "ivory"
        }

        let rawHue: Double
        if delta == 0 {
            rawHue = 0
        } else if maximum == rf {
            rawHue = 60 * (((gf - bf) / delta).truncatingRemainder(dividingBy: 6))
        } else if maximum == gf {
            rawHue = 60 * (((bf - rf) / delta) + 2)
        } else {
            rawHue = 60 * (((rf - gf) / delta) + 4)
        }
        let hue = rawHue < 0 ? rawHue + 360 : rawHue

        if brightness < 0.32 {
            if hue < 18 || hue >= 345 { return "burgundy" }
            if hue < 45 { return "brown" }
            if hue < 80 { return "olive" }
            if hue < 170 { return "forest green" }
            if hue < 260 { return "navy" }
            return "plum"
        }
        if hue < 15 || hue >= 345 { return brightness > 0.75 ? "coral" : "red" }
        if hue < 38 { return brightness > 0.72 ? "peach" : "rust" }
        if hue < 65 { return brightness > 0.72 ? "mustard" : "brown" }
        if hue < 155 { return brightness > 0.55 ? "green" : "olive" }
        if hue < 195 { return "teal" }
        if hue < 255 { return brightness < 0.55 ? "navy" : "blue" }
        if hue < 290 { return "purple" }
        return brightness > 0.65 ? "pink" : "magenta"
    }
}
