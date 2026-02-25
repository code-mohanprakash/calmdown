import Foundation
import SwiftUI

@MainActor
final class ChartsViewModel: ObservableObject {
    @Published var selectedPeriod: ChartPeriod = .daily
    @Published var readings:       [HRVReading] = []
    @Published var weeklyData:     [(Date, Double)] = []
    @Published var isLoading = false

    private let healthKit = HealthKitService.shared

    var currentStress: StressLevel {
        guard let latest = readings.last else { return .normal }
        return latest.stressLevel
    }

    var averageHRV: Double {
        HRVAnalysisService.dailyAverage(readings: readings)
    }

    func loadData() async {
        isLoading = true
        try? await healthKit.requestAuthorization()

        let days: Int
        switch selectedPeriod {
        case .hourly:  days = 1
        case .daily:   days = 7
        case .monthly: days = 30
        case .yearly:  days = 365
        }

        let realReadings = await healthKit.fetchHRVHistory(days: days)
        if !realReadings.isEmpty {
            readings     = realReadings
            weeklyData   = HRVAnalysisService.weeklyAverages(readings: realReadings)
        } else {
            readings   = []
            weeklyData = []
        }
        isLoading = false
    }
}

enum ChartPeriod: String, CaseIterable {
    case hourly  = "Hourly"
    case daily   = "Daily"
    case monthly = "Monthly"
    case yearly  = "Yearly"
}
