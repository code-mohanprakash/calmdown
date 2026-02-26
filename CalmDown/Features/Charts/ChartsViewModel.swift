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

        let realReadings: [HRVReading]
        switch selectedPeriod {
        case .hourly:
            realReadings = await healthKit.fetchHRVHistory(hours: 24)
        case .daily:
            realReadings = await healthKit.fetchHRVHistory(days: 7)
        case .monthly:
            realReadings = await healthKit.fetchHRVHistory(days: 30)
        case .yearly:
            realReadings = await healthKit.fetchHRVHistory(days: 365)
        }

        if !realReadings.isEmpty {
            readings = realReadings
            if selectedPeriod == .hourly {
                weeklyData = HRVAnalysisService.hourlyReadings(readings: realReadings)
            } else {
                weeklyData = HRVAnalysisService.weeklyAverages(readings: realReadings)
            }
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
