import SwiftUI

// Widgets are a separate target, so they need their own Color+Hex
extension Color {
    init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    static let widgetMint      = Color(red: 0.659, green: 0.835, blue: 0.729)
    static let widgetNavy      = Color(red: 0.102, green: 0.122, blue: 0.227)
    static let widgetCream     = Color(red: 0.973, green: 0.976, blue: 0.980)
    static let widgetLavender  = Color(red: 0.769, green: 0.659, blue: 0.835)
}

extension Date {
    var widgetTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: self)
    }
}
