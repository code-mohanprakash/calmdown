import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var currentHRV:    Double      = 51
    @Published var stressLevel:   StressLevel = .great
    @Published var heartRate:     Double      = 72
    @Published var hrvReadings:   [HRVReading] = []
    @Published var isLoading      = false
    @Published var userName:      String      = "Alex"

    private let healthKit  = HealthKitService.shared

    var trendArrow: String {
        HRVAnalysisService.trend(readings: hrvReadings).symbol
    }

    var dailyAverageHRV: Double {
        HRVAnalysisService.dailyAverage(readings: hrvReadings)
    }

    init() {
        // Load saved user name
        userName = UserDefaults.standard.string(forKey: "userName") ?? "Alex"
        // Load mock data immediately
        loadMockData()
    }

    func loadData() async {
        isLoading = true
        do {
            try await healthKit.requestAuthorization()
            await healthKit.refreshAll()

            let realHRV      = healthKit.latestHRV
            let realHR       = healthKit.latestHeartRate
            let readings24h  = await healthKit.fetchHRVHistory(hours: 24)

            if realHRV > 0 {
                currentHRV  = realHRV
                stressLevel = StressLevel.from(hrv: realHRV)
            }
            if realHR > 0 { heartRate = realHR }
            if !readings24h.isEmpty { hrvReadings = readings24h }

        } catch {
            print("HealthKit auth error:", error)
        }
        isLoading = false
    }

    private func loadMockData() {
        let mock = HRVReading.mockReadings(count: 24)
        hrvReadings  = mock
        currentHRV   = mock.last?.value ?? 51
        stressLevel  = StressLevel.from(hrv: currentHRV)
    }
}
