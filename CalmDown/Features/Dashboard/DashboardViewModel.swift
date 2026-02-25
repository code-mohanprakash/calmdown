import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var currentHRV:    Double      = 0
    @Published var stressLevel:   StressLevel = .normal
    @Published var heartRate:     Double      = 0
    @Published var hrvReadings:   [HRVReading] = []
    @Published var isLoading      = true
    @Published var hasData        = false

    private let healthKit  = HealthKitService.shared

    var trendArrow: String {
        HRVAnalysisService.trend(readings: hrvReadings).symbol
    }

    var dailyAverageHRV: Double {
        HRVAnalysisService.dailyAverage(readings: hrvReadings)
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
                hasData     = true
                AppGroupStore.saveHRV(realHRV, stress: stressLevel.rawValue)
            }
            if realHR > 0 { heartRate = realHR }
            if !readings24h.isEmpty { hrvReadings = readings24h }

        } catch {
            print("HealthKit auth error:", error)
        }
        isLoading = false
    }
}
