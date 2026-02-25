import SwiftUI
import Charts

struct InsightsView: View {
    @State private var selectedFilter = "Last Week"
    @State private var actionsData: [InsightBar] = InsightBar.mock()

    let filters = ["Last Week", "Run", "Meditation", "Sleep"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmLightBlue.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Filter chips
                        filterChips

                        // Actions vs Stress chart
                        actionsVsStressCard

                        // Key Actions
                        keyActionsCard

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter)
                            .font(.calmCaption)
                            .foregroundStyle(selectedFilter == filter ? .white : .secondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                selectedFilter == filter
                                    ? AnyShapeStyle(Color.calmMint)
                                    : AnyShapeStyle(Color.secondary.opacity(0.15)),
                                in: Capsule()
                            )
                    }
                }
            }
        }
    }

    private var actionsVsStressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Actions v.s. Stress Trends")
                    .font(.calmHeadline)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.calmMint)
                    .font(.caption)
            }

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: .calmMint,  label: "Meets Filter")
                legendItem(color: .calmCoral, label: "Does Not Meet Filter")
            }
            .font(.calmCaption2)

            Chart {
                ForEach(actionsData) { bar in
                    BarMark(
                        x: .value("Day",   bar.date),
                        y: .value("Score", bar.meetsFilter)
                    )
                    .foregroundStyle(Color.calmMint)
                    .cornerRadius(3)

                    BarMark(
                        x: .value("Day",   bar.date),
                        y: .value("Score", bar.doesNotMeet)
                    )
                    .foregroundStyle(Color.calmCoral.opacity(0.7))
                    .cornerRadius(3)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var keyActionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Key Actions")
                    .font(.calmHeadline)
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.calmMint)
                    .font(.caption)
                Spacer()
                Text("Level of Positive Impact")
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
            }

            Text("Positive")
                .font(.calmCaption)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xs)

            ForEach(KeyAction.mockPositive) { action in
                KeyActionRow(action: action)
            }

            Text("Negative")
                .font(.calmCaption)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.sm)

            ForEach(KeyAction.mockNegative) { action in
                KeyActionRow(action: action)
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Supporting models
struct InsightBar: Identifiable {
    let id = UUID()
    let date: Date
    let meetsFilter: Double
    let doesNotMeet: Double

    static func mock() -> [InsightBar] {
        (0..<14).map { i in
            InsightBar(
                date:         Date().daysAgo(14 - i),
                meetsFilter:  Double.random(in: 2...8),
                doesNotMeet:  Double.random(in: 1...5)
            )
        }
    }
}

struct KeyAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let impact: String

    static let mockPositive: [KeyAction] = [
        KeyAction(icon: "drop.fill",       title: "2,000+ml water", subtitle: "11 days",  impact: "Medium"),
        KeyAction(icon: "bed.double.fill",  title: "7+ hrs sleep",   subtitle: "8 days",   impact: "Medium"),
        KeyAction(icon: "figure.walk",     title: "8,000+ steps",   subtitle: "6 days",   impact: "Low"),
    ]

    static let mockNegative: [KeyAction] = [
        KeyAction(icon: "cup.and.saucer.fill", title: "3+ coffees", subtitle: "5 days", impact: "High"),
        KeyAction(icon: "moon.zzz.fill",       title: "Late bedtime", subtitle: "3 days", impact: "Medium"),
    ]
}

struct KeyActionRow: View {
    let action: KeyAction

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: action.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.calmMint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.calmBody)
                Text(action.subtitle)
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(action.impact)
                .font(.calmCaption)
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    InsightsView()
}
