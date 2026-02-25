import SwiftUI

@main
struct CalmDownWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchDashboardView()
            }
        }
    }
}
