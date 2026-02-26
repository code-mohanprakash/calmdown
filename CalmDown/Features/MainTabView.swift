import SwiftUI

struct MainTabView: View {
    @State private var selectedTab    = 0
    @State private var showWatchFaces = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home",     systemImage: "house.fill") }
                .tag(0)

            ChartsView()
                .tabItem { Label("Trends",   systemImage: "chart.xyaxis.line") }
                .tag(1)

            MoodView()
                .tabItem { Label("Track",    systemImage: "plus.circle.fill") }
                .tag(2)

            ActionsView()
                .tabItem { Label("Actions",  systemImage: "heart.fill") }
                .tag(3)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "lightbulb.fill") }
                .tag(4)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(5)
        }
        .tint(Color.calmBlue)
        .sheet(isPresented: $showWatchFaces) {
            WatchFacesView()
        }
        // Watch Faces accessible from Dashboard toolbar (see DashboardView)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTrack"))) { _ in
            selectedTab = 2
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
