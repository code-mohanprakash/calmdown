import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var storeKit: StoreKitService
    @State private var showingTracking  = false
    @State private var showWatchFaces   = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home",     systemImage: "house.fill")
                }
                .tag(0)

            ChartsView()
                .tabItem {
                    Label("Trends",   systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            // Center tracking tab
            MoodView()
                .tabItem {
                    Label("Track",    systemImage: "plus.circle.fill")
                }
                .tag(2)

            ActionsView()
                .tabItem {
                    Label("Actions",  systemImage: "heart.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.calmMint)
        .sheet(isPresented: $showWatchFaces) {
            WatchFacesView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
