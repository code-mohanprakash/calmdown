import SwiftUI

enum StressLevel: String, CaseIterable, Codable {
    case great    = "Great"
    case good     = "Good"
    case normal   = "Normal"
    case high     = "High"
    case overload = "Overload"

    var color: Color {
        switch self {
        case .great:    return .stressGreat
        case .good:     return .stressGood
        case .normal:   return .stressNormal
        case .high:     return .stressHigh
        case .overload: return .stressOverload
        }
    }

    /// HRV (SDNN) ranges in ms — higher is better/calmer
    var hrv: ClosedRange<Double> {
        switch self {
        case .great:    return 60...200
        case .good:     return 45...59
        case .normal:   return 30...44
        case .high:     return 15...29
        case .overload: return 0...14
        }
    }

    var description: String {
        switch self {
        case .great:
            return "Your stress levels are very low. You're in excellent shape!"
        case .good:
            return "Your body is recovering well. Keep it up!"
        case .normal:
            return "Stress is within normal range. Consider a short break."
        case .high:
            return "Elevated stress detected. Try some deep breathing."
        case .overload:
            return "Very high stress. Rest and recovery are essential now."
        }
    }

    var emoji: String {
        switch self {
        case .great:    return "😎"
        case .good:     return "🙂"
        case .normal:   return "😐"
        case .high:     return "😟"
        case .overload: return "😰"
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
        for level in StressLevel.allCases {
            if level.hrv.contains(hrv) { return level }
        }
        return .overload
    }
}
