import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var stressAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(stressAlertsEnabled, forKey: "stressAlerts") }
    }
    @Published var hydrationRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(hydrationRemindersEnabled, forKey: "hydrationReminders") }
    }
    @Published var selectedTheme: AppTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: "appTheme") }
    }

    @Published var showPremium   = false
    @Published var showBreathing = false

    private let storeKit = StoreKitService.shared

    var isPremium: Bool { storeKit.isPremium }

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
