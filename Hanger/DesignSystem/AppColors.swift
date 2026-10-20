import SwiftUI
import UIKit

extension Color {
    static let wardrobeBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.078, blue: 0.085, alpha: 1)
            : UIColor(red: 0.965, green: 0.949, blue: 0.918, alpha: 1)
    })
    static let wardrobeChip = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.155, blue: 0.16, alpha: 1)
            : UIColor(red: 0.91, green: 0.89, blue: 0.85, alpha: 1)
    })
    static let wardrobeInterior = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.125, blue: 0.13, alpha: 1)
            : UIColor(red: 0.94, green: 0.925, blue: 0.89, alpha: 1)
    })
    static let wardrobeInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.14, green: 0.16, blue: 0.14, alpha: 1)
    })
    static let wardrobeAccent = Color(red: 0.70, green: 0.43, blue: 0.22)
    static let wardrobeWoodLight = Color(red: 0.70, green: 0.48, blue: 0.30)
    static let wardrobeWoodDark = Color(red: 0.37, green: 0.23, blue: 0.15)
    static let wardrobeWoodHighlight = Color(red: 0.87, green: 0.70, blue: 0.49)
    static let wardrobeMetal = Color(red: 0.47, green: 0.48, blue: 0.46)

    init(hex: String) {
        let normalized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(normalized, radix: 16) ?? 0x888888
        let r, g, b: Double
        if normalized.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
