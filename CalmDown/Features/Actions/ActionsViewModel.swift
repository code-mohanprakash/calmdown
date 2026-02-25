import Foundation

@MainActor
final class ActionsViewModel: ObservableObject {
    @Published var metrics:    WellnessMetrics = .empty
    @Published var sleep:      SleepData?      = nil
    @Published var isLoading   = false

    private let healthKit = HealthKitService.shared

    func loadData() async {
        isLoading = true
        try? await healthKit.requestAuthorization()
        await fetchMetrics()
        isLoading = false
    }

    private func fetchMetrics() async {
        async let calories    = healthKit.fetchTodayActiveCalories()
        async let exerciseMin = healthKit.fetchTodayExerciseMinutes()
        async let standHours  = healthKit.fetchTodayStandHours()
        async let daylight    = healthKit.fetchTodayDaylightMinutes()
        async let mindful     = healthKit.fetchTodayMindfulMinutes()
        async let steps       = healthKit.fetchTodaySteps()
        async let noise       = healthKit.fetchTodayNoiseLevel()
        async let rhr         = healthKit.fetchRestingHeartRate()
        async let hr          = healthKit.fetchLatestHeartRate()
        async let sleepResult = healthKit.fetchLastNightSleep()

        let (cal, exMin, stand, day, mind, step, noiseLvl, rhrVal, hrVal, sleepData) =
            await (calories, exerciseMin, standHours, daylight, mindful, steps, noise, rhr, hr, sleepResult)

        metrics = WellnessMetrics(
            sleepDuration:      sleepData?.totalDuration    ?? 0,
            sleepQuality:       sleepData?.quality          ?? .fair,
            sleepHeartRate:     sleepData?.averageHeartRate ?? 0,
            activeCalories:     cal   > 0 ? cal   : 0,
            exerciseMinutes:    exMin > 0 ? exMin : 0,
            standHours:         stand > 0 ? Int(stand) : 0,
            daylightMinutes:    day   > 0 ? day   : 0,
            mindfulnessMinutes: mind  > 0 ? mind  : 0,
            stepCount:          step  > 0 ? Int(step) : 0,
            noiseLevel:         noiseLvl ?? 0,
            restingHeartRate:   rhrVal   ?? 0,
            heartRate:          hrVal    ?? 0
        )

        sleep = sleepData
    }
}
