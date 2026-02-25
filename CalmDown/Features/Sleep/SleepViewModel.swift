import Foundation

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var sleepData:     SleepData?  = nil   // nil = no data yet
    @Published var heartRateData: [(Date, Double)] = []
    @Published var isLoading = false

    private let healthKit = HealthKitService.shared

    func loadData() async {
        isLoading = true
        try? await healthKit.requestAuthorization()

        if let real = await healthKit.fetchLastNightSleep() {
            sleepData = real
        }

        // Heart rate during last night's sleep window
        let bedtime  = Calendar.current.date(byAdding: .hour, value: -9, to: Date()) ?? Date()
        let wakeTime = Date()
        let hrData   = await healthKit.fetchHeartRateSamples(from: bedtime, to: wakeTime)
        if !hrData.isEmpty { heartRateData = hrData }

        isLoading = false
    }
}
