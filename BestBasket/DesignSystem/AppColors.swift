import SwiftUI

enum AppPalette {
    static let oat = Color(hex: 0xF3EFE6)
    static let white = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x1D1B16)
    static let muted = Color(hex: 0x6B6556)
    static let cobalt = Color(hex: 0x2B45F5)
    static let tomato = Color(hex: 0xFF5B35)
    static let pine = Color(hex: 0x0E5C45)
    static let marigold = Color(hex: 0xFFC130)
    static let blush = Color(hex: 0xFFC9D4)
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}
