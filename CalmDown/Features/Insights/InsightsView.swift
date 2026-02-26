import SwiftUI
import SwiftData
import Charts

// MARK: - View

struct InsightsView: View {
    @StateObject private var vm = InsightsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDays = 14

    private let dayOptions = [7, 14, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmLightBlue.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.lg) {
                            periodPicker
                            hrvTrendCard
                            moodPatternCard
                            keyActionsCard
                            Spacer(minLength: Spacing.xxl)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.loadData(context: modelContext, days: selectedDays) }
        .onChange(of: selectedDays) { _, days in
            Task { await vm.loadData(context: modelContext, days: days) }
        }
    }

    // MARK: - Period picker
    private var periodPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(dayOptions, id: \.self) { days in
                Button {
                    selectedDays = days
                } label: {
                    Text("\(days) Days")
                        .font(.calmCaption)
                        .foregroundStyle(selectedDays == days ? .white : .secondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            selectedDays == days
                                ? AnyShapeStyle(Color.calmBlue)
                                : AnyShapeStyle(Color.secondary.opacity(0.12)),
                            in: Capsule()
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - HRV Trend chart
    private var hrvTrendCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HRV Stress Trend")
                        .font(.calmHeadline)
                    if !vm.dailyHRVPoints.isEmpty {
                        Text("Avg \(Int(vm.averageHRV))ms · \(vm.dailyHRVPoints.count) days of data")
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                // Legend
                HStack(spacing: Spacing.sm) {
                    legendDot(color: .stressGreat, label: "Low")
                    legendDot(color: .stressHigh,  label: "High")
                }
                .font(.calmCaption2)
            }

            if vm.dailyHRVPoints.isEmpty {
                noDataPlaceholder(
                    icon: "waveform.path.ecg",
                    message: "Wear your Apple Watch daily to build stress trend data."
                )
                .frame(height: 140)
            } else {
                Chart {
                    ForEach(vm.dailyHRVPoints) { point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("HRV",  point.hrv)
                        )
                        .foregroundStyle(point.stressColor)
                        .cornerRadius(4)
                    }
                    // Goal line at 45ms
                    RuleMark(y: .value("Goal", 45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.4))
                        .annotation(position: .leading) {
                            Text("Goal").font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, vm.dailyHRVPoints.count / 7))) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 30, 60, 90]) { v in
                        AxisValueLabel { Text("\(v.as(Int.self) ?? 0)ms").font(.system(size: 9)) }
                        AxisGridLine()
                    }
                }
                .frame(height: 160)
                .animation(.easeInOut(duration: 0.6), value: vm.dailyHRVPoints.count)
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Key Actions
    private var keyActionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Key Actions")
                    .font(.calmHeadline)
                Spacer()
                Text("Past \(selectedDays) days")
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
            }

            if vm.keyActions.isEmpty && !vm.isLoading {
                noDataPlaceholder(
                    icon: "chart.bar.xaxis",
                    message: "Log water, mood, and track activity to see which habits improve your HRV."
                )
            } else {
                if vm.hasPositive {
                    sectionLabel("Positive Impact")
                    ForEach(vm.keyActions.filter { $0.isPositive }) { action in
                        KeyActionRow(action: action)
                    }
                }

                if vm.hasNegative {
                    sectionLabel("Needs Attention")
                        .padding(.top, Spacing.xs)
                    ForEach(vm.keyActions.filter { !$0.isPositive }) { action in
                        KeyActionRow(action: action)
                    }
                }

                if !vm.hasPositive && !vm.hasNegative && !vm.keyActions.isEmpty {
                    ForEach(vm.keyActions) { action in
                        KeyActionRow(action: action)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Mood Pattern card
    private var moodPatternCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Mood Patterns")
                    .font(.calmHeadline)
                Spacer()
                Text("Past \(selectedDays) days")
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
            }

            if let summary = vm.moodSummary {
                HStack(spacing: Spacing.md) {
                    // Most felt
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(Color.calmBlue.opacity(0.12)).frame(width: 48, height: 48)
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.calmBlue)
                        }
                        Text(summary.topEmotion)
                            .font(.calmCaption)
                            .fontWeight(.semibold)
                        Text("Most felt")
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 60)

                    // Avg energy
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.12)).frame(width: 48, height: 48)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                        }
                        Text(String(format: "%.1f/5", summary.avgEnergy))
                            .font(.calmCaption)
                            .fontWeight(.semibold)
                        Text("Avg energy")
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 60)

                    // Positive ratio
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.12)).frame(width: 48, height: 48)
                            Text("\(Int(summary.positiveRatio * 100))%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.green)
                        }
                        Text("\(summary.totalLogs) logs")
                            .font(.calmCaption)
                            .fontWeight(.semibold)
                        Text("Positive mood")
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                if let trigger = summary.topTrigger {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.calmCoral)
                        Text("Top stress trigger: ")
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                        Text(trigger)
                            .font(.calmCaption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.calmCoral)
                    }
                    .padding(.top, Spacing.xs)
                }

            } else {
                noDataPlaceholder(
                    icon: "face.smiling",
                    message: "Log your mood in the Track tab to see patterns here."
                )
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.calmCaption)
            .foregroundStyle(.secondary)
            .padding(.top, Spacing.xs)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }

    private func noDataPlaceholder(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Color.calmBlue.opacity(0.4))
            Text(message)
                .font(.calmCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView().tint(Color.calmBlue)
            Text("Analysing your data…")
                .font(.calmCaption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Row view

struct KeyActionRow: View {
    let action: KeyActionItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: action.icon)
                .font(.system(size: 18))
                .foregroundStyle(action.isPositive ? Color.stressGreat : Color.stressHigh)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title).font(.calmBody)
                Text(action.subtitle).font(.calmCaption2).foregroundStyle(.secondary)
            }

            Spacer()

            Text(action.impact)
                .font(.calmCaption)
                .foregroundStyle(action.isPositive ? Color.stressGreat : Color.stressHigh)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (action.isPositive ? Color.stressGreat : Color.stressHigh).opacity(0.12),
                    in: Capsule()
                )
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - ViewModel

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var dailyHRVPoints: [DailyHRVPoint] = []
    @Published var keyActions:     [KeyActionItem]  = []
    @Published var isLoading = false
    @Published var moodSummary: MoodSummary? = nil

    struct MoodSummary {
        let topEmotion: String
        let topTrigger: String?
        let avgEnergy: Double
        let totalLogs: Int
        let positiveRatio: Double  // 0.0–1.0
    }

    private let healthKit = HealthKitService.shared

    var averageHRV: Double {
        guard !dailyHRVPoints.isEmpty else { return 0 }
        return dailyHRVPoints.map(\.hrv).reduce(0, +) / Double(dailyHRVPoints.count)
    }

    var hasPositive: Bool { keyActions.contains { $0.isPositive } }
    var hasNegative: Bool { keyActions.contains { !$0.isPositive } }

    func loadData(context: ModelContext, days: Int) async {
        isLoading = true
        try? await healthKit.requestAuthorization()

        // ── HRV trend ──────────────────────────────────────────────
        let readings = await healthKit.fetchHRVHistory(days: days)
        if !readings.isEmpty {
            let cal = Calendar.current
            let grouped = Dictionary(grouping: readings) {
                cal.startOfDay(for: $0.timestamp)
            }
            dailyHRVPoints = grouped
                .map { (date, samples) in
                    let avg = samples.map(\.value).reduce(0, +) / Double(samples.count)
                    return DailyHRVPoint(date: date, hrv: avg)
                }
                .sorted { $0.date < $1.date }
        } else {
            dailyHRVPoints = []
        }

        // ── Key Actions from real data ─────────────────────────────
        await computeKeyActions(context: context, days: days)

        // ── Mood summary ───────────────────────────────────────────
        await computeMoodSummary(context: context, days: days)

        isLoading = false
    }

    private func computeKeyActions(context: ModelContext, days: Int) async {
        var actions: [KeyActionItem] = []
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // --- Hydration (SwiftData) ---
        let hydrationFetch = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { $0.timestamp >= cutoff }
        )
        if let entries = try? context.fetch(hydrationFetch), !entries.isEmpty {
            let totalWater = entries.reduce(0) { $0 + $1.waterMl }
            let goalDays   = Set(entries.filter { $0.waterMl >= 2000 }
                .map { cal.startOfDay(for: $0.timestamp) }).count
            let avgDaily   = totalWater / max(days, 1)

            if goalDays > 0 {
                actions.append(KeyActionItem(
                    icon: "drop.fill",
                    title: "Hydration goal ≥2000ml",
                    subtitle: "\(goalDays) day\(goalDays == 1 ? "" : "s") hit · avg \(avgDaily)ml/day",
                    impact: goalDays >= days / 2 ? "Strong" : "Moderate",
                    isPositive: true
                ))
            }

            // High caffeine days
            let highCaffDays = Set(entries.filter { $0.caffeineMg >= 300 }
                .map { cal.startOfDay(for: $0.timestamp) }).count
            if highCaffDays > 0 {
                actions.append(KeyActionItem(
                    icon: "cup.and.saucer.fill",
                    title: "High caffeine days (≥300mg)",
                    subtitle: "\(highCaffDays) day\(highCaffDays == 1 ? "" : "s") in period",
                    impact: "Watch",
                    isPositive: false
                ))
            }
        }

        // --- Steps (HealthKit — today) ---
        let steps = await healthKit.fetchTodaySteps()
        if steps > 0 {
            let hit = steps >= 8000
            actions.append(KeyActionItem(
                icon: "figure.walk",
                title: "Steps today",
                subtitle: "\(Int(steps).formatted()) steps · goal 8,000",
                impact: hit ? "On track" : "Below goal",
                isPositive: hit
            ))
        }

        // --- Sleep (HealthKit — last night) ---
        if let sleep = await healthKit.fetchLastNightSleep(), sleep.totalDuration > 0 {
            let hours    = sleep.totalDuration / 3600
            let goodSleep = hours >= 7
            actions.append(KeyActionItem(
                icon: "bed.double.fill",
                title: "Last night's sleep",
                subtitle: String(format: "%.1f hrs · quality: %@", hours, sleep.quality.rawValue),
                impact: goodSleep ? "Restorative" : "Short",
                isPositive: goodSleep
            ))
        }

        // --- Mindfulness (HealthKit — today) ---
        let mindful = await healthKit.fetchTodayMindfulMinutes()
        if mindful > 0 {
            actions.append(KeyActionItem(
                icon: "figure.mind.and.body",
                title: "Mindfulness today",
                subtitle: "\(Int(mindful)) min",
                impact: mindful >= 5 ? "Beneficial" : "Getting there",
                isPositive: true
            ))
        }

        keyActions = actions
    }

    private func computeMoodSummary(context: ModelContext, days: Int) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.timestamp >= cutoff }
        )
        guard let entries = try? context.fetch(descriptor), !entries.isEmpty else {
            moodSummary = nil
            return
        }

        // Top emotion
        let emotionCounts = Dictionary(grouping: entries, by: \.emotion).mapValues(\.count)
        let topEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "—"

        // Top trigger
        let allTriggers = entries.flatMap { $0.triggers.split(separator: ",").map(String.init) }
        let triggerCounts = Dictionary(grouping: allTriggers, by: { $0 }).mapValues(\.count)
        let topTrigger = triggerCounts.max(by: { $0.value < $1.value })?.key

        // Avg energy
        let avgEnergy = entries.map { Double($0.energyLevel) }.reduce(0, +) / Double(entries.count)

        // Positive ratio — energyLevel >= 3 as positive proxy
        let positiveCount = entries.filter { $0.energyLevel >= 3 }.count
        let positiveRatio = Double(positiveCount) / Double(entries.count)

        moodSummary = MoodSummary(
            topEmotion: topEmotion,
            topTrigger: topTrigger,
            avgEnergy: avgEnergy,
            totalLogs: entries.count,
            positiveRatio: positiveRatio
        )
    }
}

// MARK: - Models

struct DailyHRVPoint: Identifiable {
    let id   = UUID()
    let date: Date
    let hrv:  Double

    var stressColor: Color {
        StressLevel.from(hrv: hrv).color
    }
}

struct KeyActionItem: Identifiable {
    let id         = UUID()
    let icon:       String
    let title:      String
    let subtitle:   String
    let impact:     String
    let isPositive: Bool
}

#Preview {
    InsightsView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HydrationEntry.self, MoodEntry.self, HRVReading.self], inMemory: true)
}
