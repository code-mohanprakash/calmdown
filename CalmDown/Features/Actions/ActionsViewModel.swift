import Foundation

@MainActor
final class ActionsViewModel: ObservableObject {
    @Published var metrics: WellnessMetrics = .preview
    @Published var sleep:   SleepData       = .preview
    @Published var isLoading = false

    private let healthKit = HealthKitService.shared

    func loadData() async {
        isLoading = true
        await fetchMetrics()
        isLoading = false
    }

    private func fetchMetrics() async {
        async let calories     = healthKit.fetchTodayActiveCalories()
        async let exerciseMin  = healthKit.fetchTodayExerciseMinutes()
        async let standHours   = healthKit.fetchTodayStandHours()
        async let daylight     = healthKit.fetchTodayDaylightMinutes()
        async let mindful      = healthKit.fetchTodayMindfulMinutes()
        async let steps        = healthKit.fetchTodaySteps()
        async let noise        = healthKit.fetchTodayNoiseLevel()
        async let rhr          = healthKit.fetchRestingHeartRate()
        async let hr           = healthKit.fetchLatestHeartRate()
        async let sleep        = healthKit.fetchLastNightSleep()

        let (cal, exMin, stand, day, mind, step, noiseLvl, rhrVal, hrVal, sleepData) =
            await (calories, exerciseMin, standHours, daylight, mindful, steps, noise, rhr, hr, sleep)

        metrics = WellnessMetrics(
            sleepDuration:      sleepData?.totalDuration   ?? metrics.sleepDuration,
            sleepQuality:       sleepData?.quality         ?? metrics.sleepQuality,
            sleepHeartRate:     sleepData?.averageHeartRate ?? metrics.sleepHeartRate,
            activeCalories:     cal  > 0 ? cal  : metrics.activeCalories,
            exerciseMinutes:    exMin > 0 ? exMin : metrics.exerciseMinutes,
            standHours:         stand > 0 ? Int(stand) : metrics.standHours,
            daylightMinutes:    day   > 0 ? day   : metrics.daylightMinutes,
            mindfulnessMinutes: mind  > 0 ? mind  : metrics.mindfulnessMinutes,
            stepCount:          step  > 0 ? Int(step) : metrics.stepCount,
            noiseLevel:         noiseLvl ?? metrics.noiseLevel,
            restingHeartRate:   rhrVal ?? metrics.restingHeartRate,
            heartRate:          hrVal  ?? metrics.heartRate
        )

        if let sd = sleepData { self.sleep = sd }
    }
}
