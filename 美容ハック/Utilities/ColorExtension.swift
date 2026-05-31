import SwiftUI

extension Color {
    static let beautyRose      = Color(hex: "#E8A4A4")
    static let beautyBG        = Color(hex: "#FAF8F6")
    static let beautyCard      = Color(hex: "#FFFFFF")
    static let beautyText      = Color(hex: "#1A1A1A")
    static let beautySubText   = Color(hex: "#888888")
    static let beautyDark      = Color(hex: "#1A1A1A")

    static let beautyAlertRed    = Color(hex: "#FF4444")
    static let beautyAlertOrange = Color(hex: "#FF8C00")

    static let contactBlue   = Color(hex: "#4A90D9")
    static let surgeryPurple = Color(hex: "#9B72CF")
    static let esteRose      = Color(hex: "#E88FA0")
    static let lashBrown     = Color(hex: "#C4956A")
    static let permYellow    = Color(hex: "#F5C842")
    static let skinGreen     = Color(hex: "#7BC67E")
    static let nailPink      = Color(hex: "#F4A7B9")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
