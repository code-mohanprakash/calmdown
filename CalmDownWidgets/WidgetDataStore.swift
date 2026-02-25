import Foundation
import SwiftUI

/// Shared data store between main app and widgets via App Group UserDefaults
struct WidgetDataStore {
    static let suiteName = "group.com.calmdown.app"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Write (called from main app)
    static func saveHRV(_ hrv: Double, stress: String) {
        defaults?.set(hrv, forKey: "widget_hrv")
        defaults?.set(stress, forKey: "widget_stress")
        defaults?.set(Date(), forKey: "widget_hrv_date")
    }

    static func saveSleep(duration: String, quality: String) {
        defaults?.set(duration, forKey: "widget_sleep_duration")
        defaults?.set(quality,  forKey: "widget_sleep_quality")
    }

    // MARK: - Read (called from widgets)
    static var hrv: Double       { defaults?.double(forKey: "widget_hrv") ?? 0 }
    static var stress: String    { defaults?.string(forKey: "widget_stress") ?? "Normal" }
    static var stressColor: Color {
        switch stress {
        case "Great":    return .green
        case "Good":     return Color(red: 0.545, green: 0.765, blue: 0.290)
        case "Normal":   return .yellow
        case "High":     return .orange
        default:         return .red
        }
    }

    static var sleepDuration: String { defaults?.string(forKey: "widget_sleep_duration") ?? "--:--" }
    static var sleepQuality:  String { defaults?.string(forKey: "widget_sleep_quality")  ?? "---" }

    static var hasRealData: Bool { hrv > 0 }
}
