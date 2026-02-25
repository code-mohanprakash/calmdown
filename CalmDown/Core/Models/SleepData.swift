import Foundation

struct SleepData: Identifiable {
    let id: UUID
    let date: Date
    let totalDuration: TimeInterval   // seconds
    let remDuration: TimeInterval
    let deepDuration: TimeInterval
    let coreDuration: TimeInterval
    let awakeTime: TimeInterval
    let averageHeartRate: Double      // bpm
    let quality: SleepQuality
    let stages: [SleepStage]

    var durationString: String {
        let hours   = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours):\(String(format: "%02d", minutes))"
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalDuration: TimeInterval = 29400,
        remDuration: TimeInterval = 5400,
        deepDuration: TimeInterval = 7200,
        coreDuration: TimeInterval = 14400,
        awakeTime: TimeInterval = 1800,
        averageHeartRate: Double = 67,
        quality: SleepQuality = .excellent,
        stages: [SleepStage] = []
    ) {
        self.id              = id
        self.date            = date
        self.totalDuration   = totalDuration
        self.remDuration     = remDuration
        self.deepDuration    = deepDuration
        self.coreDuration    = coreDuration
        self.awakeTime       = awakeTime
        self.averageHeartRate = averageHeartRate
        self.quality         = quality
        self.stages          = stages.isEmpty ? SleepStage.mock() : stages
    }

    static var preview: SleepData { SleepData() }

    /// Zero-value state for when no HealthKit data is available yet
    static var empty: SleepData {
        SleepData(totalDuration: 0, remDuration: 0, deepDuration: 0,
                  coreDuration: 0, awakeTime: 0, averageHeartRate: 0,
                  quality: .fair, stages: [SleepStage(startTime: .distantPast,
                                                       endTime: .distantPast, stage: .awake)])
    }

    var hasData: Bool { totalDuration > 0 }
}

enum SleepQuality: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good      = "Good"
    case fair      = "Fair"
    case poor      = "Poor"

    var score: Int {
        switch self {
        case .excellent: return 90
        case .good:      return 70
        case .fair:      return 50
        case .poor:      return 30
        }
    }
}

struct SleepStage: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let stage: Stage

    enum Stage: String, CaseIterable {
        case awake = "Awake"
        case rem   = "REM"
        case core  = "Core"
        case deep  = "Deep"
    }

    init(id: UUID = UUID(), startTime: Date, endTime: Date, stage: Stage) {
        self.id        = id
        self.startTime = startTime
        self.endTime   = endTime
        self.stage     = stage
    }

    static func mock() -> [SleepStage] {
        let bedtime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
        return [
            SleepStage(startTime: bedtime,                                               endTime: bedtime.addingTimeInterval(1800),  stage: .awake),
            SleepStage(startTime: bedtime.addingTimeInterval(1800),                      endTime: bedtime.addingTimeInterval(9000),  stage: .core),
            SleepStage(startTime: bedtime.addingTimeInterval(9000),                      endTime: bedtime.addingTimeInterval(14400), stage: .deep),
            SleepStage(startTime: bedtime.addingTimeInterval(14400),                     endTime: bedtime.addingTimeInterval(18000), stage: .rem),
            SleepStage(startTime: bedtime.addingTimeInterval(18000),                     endTime: bedtime.addingTimeInterval(21600), stage: .core),
            SleepStage(startTime: bedtime.addingTimeInterval(21600),                     endTime: bedtime.addingTimeInterval(27000), stage: .deep),
            SleepStage(startTime: bedtime.addingTimeInterval(27000),                     endTime: bedtime.addingTimeInterval(28800), stage: .rem),
            SleepStage(startTime: bedtime.addingTimeInterval(28800),                     endTime: bedtime.addingTimeInterval(29400), stage: .awake),
        ]
    }
}
