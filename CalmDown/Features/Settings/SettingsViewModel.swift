import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var stressAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(stressAlertsEnabled, forKey: "stressAlerts")
            if stressAlertsEnabled {
                Task { await NotificationService.shared.requestPermission() }
            }
        }
    }
    @Published var hydrationRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hydrationRemindersEnabled, forKey: "hydrationReminders")
            if hydrationRemindersEnabled {
                Task { await NotificationService.shared.requestPermission() }
                NotificationService.shared.scheduleHydrationReminder(atHour: 10)
                NotificationService.shared.scheduleHydrationReminder(atHour: 14)
                NotificationService.shared.scheduleHydrationReminder(atHour: 18)
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["hydration-10", "hydration-14", "hydration-18"]
                )
            }
        }
    }
    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: "appTheme") }
    }

    @Published var showBreathing = false


    init() {
        userName   = UserDefaults.standard.string(forKey: "userName") ?? "Alex"
        stressAlertsEnabled      = UserDefaults.standard.bool(forKey: "stressAlerts")
        hydrationRemindersEnabled = UserDefaults.standard.bool(forKey: "hydrationReminders")
        let themeRaw = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        selectedTheme = AppTheme(rawValue: themeRaw) ?? .system
    }
}

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
