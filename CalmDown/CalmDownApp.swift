import SwiftUI
import SwiftData

@main
struct CalmDownApp: App {
    @StateObject private var storeKit = StoreKitService.shared
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    var colorScheme: ColorScheme? {
        AppTheme(rawValue: themeRaw)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(colorScheme)
                .environmentObject(storeKit)
        }
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self])
    }
}
