import Foundation
import Combine
import UserNotifications

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var currentHRV:    Double      = 0
    @Published var stressLevel:   StressLevel = .normal
    @Published var heartRate:     Double      = 0
    @Published var hrvReadings:   [HRVReading] = []
    @Published var isLoading      = true
    @Published var hasData        = false
    @Published var lastRefreshed: Date?       = nil

    private let healthKit  = HealthKitService.shared
    private var cancellables = Set<AnyCancellable>()

    var trendArrow: String {
        HRVAnalysisService.trend(readings: hrvReadings).symbol
    }

    var dailyAverageHRV: Double {
        HRVAnalysisService.dailyAverage(readings: hrvReadings)
    }

    init() {
        // Subscribe to real-time HRV updates from Apple Watch
        healthKit.hrvDidUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hrv in
                guard let self else { return }
                self.applyHRV(hrv)
                // Reload 24h history silently
                Task { [weak self] in
                    guard let self else { return }
                    let readings = await self.healthKit.fetchHRVHistory(hours: 24)
                    if !readings.isEmpty { self.hrvReadings = readings }
                }
            }
            .store(in: &cancellables)
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
                applyHRV(realHRV)
            }
            if realHR > 0 { heartRate = realHR }
            if !readings24h.isEmpty { hrvReadings = readings24h }

        } catch {
            print("HealthKit auth error:", error)
        }
        isLoading = false
    }

    private func applyHRV(_ hrv: Double) {
        currentHRV  = hrv
        stressLevel = StressLevel.from(hrv: hrv)
        hasData     = true
        lastRefreshed = Date()
        AppGroupStore.saveHRV(hrv, stress: stressLevel.rawValue)
        let alertsEnabled = UserDefaults.standard.bool(forKey: "stressAlerts")
        if alertsEnabled {
            NotificationService.shared.scheduleStressAlert(stressLevel: stressLevel, hrv: hrv)
        }
    }
}
