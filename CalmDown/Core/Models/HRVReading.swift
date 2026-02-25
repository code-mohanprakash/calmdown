import Foundation
import SwiftData

@Model
final class HRVReading {
    var id: UUID
    var timestamp: Date
    var value: Double  // SDNN in ms
    var heartRate: Double?  // bpm

    var stressLevel: StressLevel {
        StressLevel.from(hrv: value)
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), value: Double, heartRate: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.heartRate = heartRate
    }
}

// MARK: - Mock Data
extension HRVReading {
    static func mockReadings(count: Int = 24) -> [HRVReading] {
        var readings: [HRVReading] = []
        let now = Date()
        let baseHRV: Double = 45
        for i in 0..<count {
            let hoursAgo = Double(count - i)
            let timestamp = Calendar.current.date(byAdding: .hour, value: -Int(hoursAgo), to: now) ?? now
            // Add some natural variation
            let variation = Double.random(in: -15...15)
            let hrv = max(10, min(100, baseHRV + variation + sin(Double(i) * 0.3) * 10))
            readings.append(HRVReading(timestamp: timestamp, value: hrv, heartRate: Double.random(in: 55...85)))
        }
        return readings
    }

    static var preview: HRVReading {
        HRVReading(timestamp: Date(), value: 51, heartRate: 68)
    }
}
