import Foundation
import WidgetKit

/// Writes shared data from the main app to the App Group so widgets can read it
struct AppGroupStore {
    static let suiteName = "group.com.calmdown.app"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func saveHRV(_ hrv: Double, stress: String) {
        defaults?.set(hrv,    forKey: "widget_hrv")
        defaults?.set(stress, forKey: "widget_stress")
        defaults?.set(Date(), forKey: "widget_hrv_date")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func saveSleep(duration: String, quality: String) {
        defaults?.set(duration, forKey: "widget_sleep_duration")
        defaults?.set(quality,  forKey: "widget_sleep_quality")
        WidgetCenter.shared.reloadTimelines(ofKind: "SleepWidget")
    }
}
