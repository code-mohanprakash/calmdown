import Foundation

struct HRVAnalysisService {
    static func stressLevel(from hrv: Double) -> StressLevel {
        return StressLevel.from(hrv: hrv)
    }

    static func trend(readings: [HRVReading]) -> HRVTrend {
        guard readings.count >= 2 else { return .stable }
        let recent = readings.suffix(3).map(\.value)
        let older  = readings.prefix(3).map(\.value)
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg  = older.reduce(0, +) / Double(older.count)
        let delta = recentAvg - olderAvg
        if delta > 5  { return .improving }
        if delta < -5 { return .declining }
        return .stable
    }

    static func dailyAverage(readings: [HRVReading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        return readings.map(\.value).reduce(0, +) / Double(readings.count)
    }

    static func weeklyAverages(readings: [HRVReading]) -> [(Date, Double)] {
        let calendar = Calendar.current
        var grouped: [Date: [Double]] = [:]
        for r in readings {
            let key = calendar.startOfDay(for: r.timestamp)
            grouped[key, default: []].append(r.value)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.reduce(0, +) / Double($0.value.count)) }
    }

    /// Returns readings bucketed by hour for today
    static func hourlyReadings(readings: [HRVReading]) -> [(Date, Double)] {
        let calendar = Calendar.current
        var grouped: [Int: [Double]] = [:]
        for r in readings {
            let hour = calendar.component(.hour, from: r.timestamp)
            grouped[hour, default: []].append(r.value)
        }
        return grouped
            .sorted { $0.key < $1.key }
            .compactMap { (hour, values) -> (Date, Double)? in
                var comps = calendar.dateComponents([.year, .month, .day], from: Date())
                comps.hour = hour
                guard let date = calendar.date(from: comps) else { return nil }
                return (date, values.reduce(0, +) / Double(values.count))
            }
    }
}

enum HRVTrend: String {
    case improving = "Improving"
    case stable    = "Stable"
    case declining = "Declining"

    var symbol: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable:    return "minus"
        case .declining: return "arrow.down.right"
        }
    }
}
