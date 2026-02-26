import WidgetKit
import SwiftUI

// MARK: - Provider
struct HRVWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HRVWidgetEntry {
        HRVWidgetEntry(date: Date(), hrv: 51, stress: "Great", stressColor: .green)
    }

    func getSnapshot(in context: Context, completion: @escaping (HRVWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HRVWidgetEntry>) -> Void) {
        let hrv    = WidgetDataStore.hrv
        let stress = WidgetDataStore.stress
        let color  = WidgetDataStore.stressColor
        let entry  = HRVWidgetEntry(date: Date(), hrv: hrv > 0 ? hrv : 51, stress: stress, stressColor: color)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct HRVWidgetEntry: TimelineEntry {
    let date: Date
    let hrv: Double
    let stress: String
    let stressColor: Color
}

// MARK: - Widget View
struct HRVWidgetView: View {
    let entry: HRVWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var hrvContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(entry.stressColor)
                    .font(.caption)
                Text("HRV")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(entry.hrv))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("ms")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(entry.stress)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(entry.stressColor)
        }
    }

    private var smallView: some View {
        hrvContent
            .padding(12)
            .containerBackground(for: .widget) {
                Color.widgetCream
            }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            hrvContent
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Stress Level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.stress)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.stressColor)
                Text("Updated \(entry.date.widgetTimeString)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color.widgetCream
        }
    }
}

// MARK: - Widget
struct HRVWidget: Widget {
    let kind = "HRVWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HRVWidgetProvider()) { entry in
            HRVWidgetView(entry: entry)
        }
        .configurationDisplayName("HRV Monitor")
        .description("See your current Heart Rate Variability and stress level.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
