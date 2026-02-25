import SwiftUI

// Shared types for Watch target (separate from iOS target)

enum StressLevel: String, CaseIterable {
    case great    = "Great"
    case good     = "Good"
    case normal   = "Normal"
    case high     = "High"
    case overload = "Overload"

    var color: Color {
        switch self {
        case .great:    return Color(red: 0.298, green: 0.686, blue: 0.314)
        case .good:     return Color(red: 0.545, green: 0.765, blue: 0.290)
        case .normal:   return Color(red: 1.0,   green: 0.757, blue: 0.027)
        case .high:     return Color(red: 1.0,   green: 0.596, blue: 0.0)
        case .overload: return Color(red: 0.957, green: 0.263, blue: 0.212)
        }
    }

    var gaugePosition: CGFloat {
        switch self {
        case .great:    return 0.9
        case .good:     return 0.7
        case .normal:   return 0.5
        case .high:     return 0.3
        case .overload: return 0.1
        }
    }

    static func from(hrv: Double) -> StressLevel {
        switch hrv {
        case 60...: return .great
        case 45..<60: return .good
        case 30..<45: return .normal
        case 15..<30: return .high
        default:      return .overload
        }
    }
}

extension Color {
    static let calmDeepGreen = Color(red: 0.176, green: 0.373, blue: 0.322)
    static let calmMint      = Color(red: 0.659, green: 0.835, blue: 0.729)
    static let calmNavy      = Color(red: 0.102, green: 0.122, blue: 0.227)

    // Stress gradient colors for watch gauge
    static let stressGreat    = Color(red: 0.298, green: 0.686, blue: 0.314)
    static let stressGood     = Color(red: 0.545, green: 0.765, blue: 0.290)
    static let stressNormal   = Color(red: 1.0,   green: 0.757, blue: 0.027)
    static let stressHigh     = Color(red: 1.0,   green: 0.596, blue: 0.0)
    static let stressOverload = Color(red: 0.957, green: 0.263, blue: 0.212)
}
