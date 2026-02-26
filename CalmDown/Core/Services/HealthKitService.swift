import HealthKit
import Foundation
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var latestHRV: Double = 0
    @Published var latestHeartRate: Double = 0
    @Published var restingHeartRate: Double = 0

    private let readTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .heartRate,
            .stepCount,
            .activeEnergyBurned,
            .appleExerciseTime,
            .appleStandTime,
            .environmentalAudioExposure,
            .timeInDaylight,
        ]
        for id in quantityTypes {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }()

    /// Fires every time a new HRV sample arrives from Apple Watch
    let hrvDidUpdate = PassthroughSubject<Double, Never>()

    private var hrvObserverQuery: HKObserverQuery?

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
        startRealtimeHRVObserver()
    }

    // MARK: - Realtime HRV Observer
    /// Registers an HKObserverQuery so the app reacts immediately when
    /// Apple Watch writes a new HRV-SDNN sample — no need to re-open the app.
    private func startRealtimeHRVObserver() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        // Stop any existing observer first
        if let existing = hrvObserverQuery { store.stop(existing) }

        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil, let self else {
                completionHandler()
                return
            }
            Task { @MainActor in
                if let latest = await self.fetchLatestHRV(), latest > 0 {
                    self.latestHRV = latest
                    self.hrvDidUpdate.send(latest)
                }
                if let hr = await self.fetchLatestHeartRate() { self.latestHeartRate = hr }
            }
            completionHandler()
        }
        hrvObserverQuery = query
        store.execute(query)

        // Background delivery: wake app when Watch syncs overnight
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
    }

    // MARK: - HRV
    func fetchLatestHRV() async -> Double? {
        return await fetchLatestQuantity(identifier: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))
    }

    func fetchHRVHistory(days: Int = 7) async -> [HRVReading] {
        let endDate   = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return await fetchHRVSamples(from: startDate, to: endDate)
    }

    func fetchHRVHistory(hours: Int) async -> [HRVReading] {
        let endDate   = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: endDate) ?? endDate
        return await fetchHRVSamples(from: startDate, to: endDate)
    }

    private func fetchHRVSamples(from startDate: Date, to endDate: Date) async -> [HRVReading] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let readings = samples.map { sample in
                    HRVReading(
                        timestamp: sample.startDate,
                        value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    )
                }
                continuation.resume(returning: readings)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Heart Rate
    func fetchLatestHeartRate() async -> Double? {
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        return await fetchLatestQuantity(identifier: .heartRate, unit: unit)
    }

    func fetchRestingHeartRate() async -> Double? {
        return await fetchLatestQuantity(identifier: .restingHeartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))
    }

    func fetchHeartRateSamples(from: Date, to: Date) async -> [(Date, Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let pairs = samples.map { ($0.startDate, $0.quantity.doubleValue(for: unit)) }
                continuation.resume(returning: pairs)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Sleep
    func fetchLastNightSleep() async -> SleepData? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date().startOfDay) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        // Step 1: fetch sleep samples
        let sleepSamples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: samples)
            }
            self.store.execute(query)
        }

        guard !sleepSamples.isEmpty else { return nil }

        let total = sleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let hours = total / 3600
        let quality: SleepQuality
        switch hours {
        case 8...:  quality = .excellent
        case 7..<8: quality = .good
        case 5..<8: quality = .fair
        default:    quality = .poor
        }

        // Step 2: fetch heart rate during the actual sleep window
        let sleepStart = sleepSamples.first!.startDate
        let sleepEnd   = sleepSamples.last!.endDate
        let hrSamples  = await fetchHeartRateSamples(from: sleepStart, to: sleepEnd)
        let avgHR: Double = hrSamples.isEmpty ? 0 : hrSamples.map(\.1).reduce(0, +) / Double(hrSamples.count)

        return SleepData(totalDuration: total, averageHeartRate: avgHR, quality: quality)
    }

    // MARK: - Fitness
    func fetchTodaySteps() async -> Double {
        return await fetchTodaySum(identifier: .stepCount, unit: HKUnit.count())
    }

    func fetchTodayActiveCalories() async -> Double {
        return await fetchTodaySum(identifier: .activeEnergyBurned, unit: HKUnit.kilocalorie())
    }

    func fetchTodayExerciseMinutes() async -> Double {
        return await fetchTodaySum(identifier: .appleExerciseTime, unit: HKUnit.minute())
    }

    func fetchTodayStandHours() async -> Double {
        return await fetchTodaySum(identifier: .appleStandTime, unit: HKUnit.minute()) / 60
    }

    func fetchTodayDaylightMinutes() async -> Double {
        return await fetchTodaySum(identifier: .timeInDaylight, unit: HKUnit.minute())
    }

    func fetchTodayMindfulMinutes() async -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return 0 }
        let (start, end) = (Date().startOfDay, Date().endOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let total = (samples ?? []).reduce(0.0) {
                    $0 + $1.endDate.timeIntervalSince($1.startDate) / 60
                }
                continuation.resume(returning: total)
            }
            self.store.execute(query)
        }
    }

    func fetchTodayNoiseLevel() async -> Double? {
        return await fetchLatestQuantity(identifier: .environmentalAudioExposure, unit: HKUnit.decibelAWeightedSoundPressureLevel())
    }

    // MARK: - Helpers
    private func fetchLatestQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            self.store.execute(query)
        }
    }

    private func fetchTodaySum(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let (start, end) = (Date().startOfDay, Date().endOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            self.store.execute(query)
        }
    }

    // MARK: - Refresh all
    func refreshAll() async {
        async let hrv        = fetchLatestHRV()
        async let hr         = fetchLatestHeartRate()
        async let rhr        = fetchRestingHeartRate()

        let (hrvVal, hrVal, rhrVal) = await (hrv, hr, rhr)
        latestHRV        = hrvVal ?? 0
        latestHeartRate  = hrVal  ?? 0
        restingHeartRate = rhrVal ?? 0
    }
}
