import WidgetKit
import SwiftUI

struct StressWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StressEntry {
        StressEntry(date: Date(), stressLevel: "Normal", hrv: 35, color: .yellow)
    }

    func getSnapshot(in context: Context, completion: @escaping (StressEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StressEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct StressEntry: TimelineEntry {
    let date: Date
    let stressLevel: String
    let hrv: Double
    let color: Color
}

struct StressWidgetView: View {
    let entry: StressEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundStyle(entry.color)

            Text(entry.stressLevel)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(entry.color)

            Text("\(Int(entry.hrv))ms HRV")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.widgetCream, entry.color.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct StressWidget: Widget {
    let kind = "StressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StressWidgetProvider()) { entry in
            StressWidgetView(entry: entry)
        }
        .configurationDisplayName("Stress Level")
        .description("Quick glance at your current stress level.")
        .supportedFamilies([.systemSmall])
    }
}
