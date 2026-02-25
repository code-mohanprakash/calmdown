import WidgetKit
import SwiftUI

struct SleepWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepWidgetEntry {
        SleepWidgetEntry(date: Date(), duration: "8:10", quality: "Excellent")
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepWidgetEntry>) -> Void) {
        let duration = WidgetDataStore.sleepDuration
        let quality  = WidgetDataStore.sleepQuality
        let entry    = SleepWidgetEntry(date: Date(), duration: duration, quality: quality)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct SleepWidgetEntry: TimelineEntry {
    let date: Date
    let duration: String
    let quality: String
}

struct SleepWidgetView: View {
    let entry: SleepWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.widgetLavender)
                    .font(.caption)
                Text("Sleep")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.duration)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(entry.quality)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.widgetLavender)

            Spacer()

            HStack {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text("Great sleep!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color.widgetNavy
                .opacity(0.05)
                .overlay(Color.widgetCream)
        }
    }
}

struct SleepWidget: Widget {
    let kind = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepWidgetProvider()) { entry in
            SleepWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleep Tracker")
        .description("Last night's sleep duration and quality.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
