import Foundation

struct WellnessMetrics {
    // Sleep
    var sleepDuration: TimeInterval   // seconds
    var sleepQuality: SleepQuality
    var sleepHeartRate: Double        // bpm

    // Fitness
    var activeCalories: Double        // kcal
    var exerciseMinutes: Double       // minutes
    var standHours: Int

    // Other
    var daylightMinutes: Double
    var mindfulnessMinutes: Double
    var stepCount: Int
    var noiseLevel: Double            // dB

    // Heart
    var restingHeartRate: Double      // bpm
    var heartRate: Double             // current bpm

    var noiseLevelCategory: String {
        switch noiseLevel {
        case ..<55: return "Low"
        case 55..<70: return "Normal"
        case 70..<85: return "High"
        default: return "Very High"
        }
    }

    static var empty: WellnessMetrics {
        WellnessMetrics(
            sleepDuration: 0, sleepQuality: .fair, sleepHeartRate: 0,
            activeCalories: 0, exerciseMinutes: 0, standHours: 0,
            daylightMinutes: 0, mindfulnessMinutes: 0, stepCount: 0,
            noiseLevel: 0, restingHeartRate: 0, heartRate: 0
        )
    }

    static var preview: WellnessMetrics {
        WellnessMetrics(
            sleepDuration: 29400,
            sleepQuality: .excellent,
            sleepHeartRate: 67,
            activeCalories: 846,
            exerciseMinutes: 46,
            standHours: 12,
            daylightMinutes: 40,
            mindfulnessMinutes: 3,
            stepCount: 3000,
            noiseLevel: 60,
            restingHeartRate: 62,
            heartRate: 72
        )
    }
}
