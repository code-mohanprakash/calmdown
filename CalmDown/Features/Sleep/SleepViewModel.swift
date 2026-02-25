import Foundation

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var sleepData:     SleepData   = .preview
    @Published var heartRateData: [(Date, Double)] = []
    @Published var isLoading = false

    private let healthKit = HealthKitService.shared

    func loadData() async {
        isLoading = true
        loadMockData()

        if let real = await healthKit.fetchLastNightSleep() {
            sleepData = real
        }

        // Heart rate during last night
        let bedtime = Calendar.current.date(byAdding: .hour, value: -9, to: Date()) ?? Date()
        let wakeTime = Date()
        let hrData = await healthKit.fetchHeartRateSamples(from: bedtime, to: wakeTime)
        if !hrData.isEmpty { heartRateData = hrData }

        isLoading = false
    }

    private func loadMockData() {
        sleepData = SleepData.preview
        heartRateData = mockHeartRateData()
    }

    private func mockHeartRateData() -> [(Date, Double)] {
        let bedtime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
        return (0..<30).map { i in
            let t = bedtime.addingTimeInterval(Double(i) * 960)
            let base: Double = 65
            let variation = sin(Double(i) * 0.5) * 8 + Double.random(in: -4...4)
            return (t, base + variation)
        }
    }
}
