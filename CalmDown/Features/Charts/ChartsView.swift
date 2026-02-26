import SwiftUI
import Charts

struct ChartsView: View {
    @StateObject private var vm = ChartsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Period selector
                        periodSelector

                        // Current status
                        statusHeader

                        // Main HRV line chart
                        mainChartCard

                        // Bar chart
                        barChartCard

                        // Scatter grid chart
                        scatterCard

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Trends & Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.loadData() }
        .onChange(of: vm.selectedPeriod) { _, _ in
            Task { await vm.loadData() }
        }
    }

    // MARK: - Subviews
    private var periodSelector: some View {
        Picker("Period", selection: $vm.selectedPeriod) {
            ForEach(ChartPeriod.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    private var statusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HRV Trend")
                    .font(.calmHeadline)
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(vm.currentStress.color)
                        .frame(width: 10, height: 10)
                    Text(vm.currentStress.rawValue)
                        .font(.calmSubheadline)
                        .foregroundStyle(vm.currentStress.color)
                    Text("HRV \(Int(vm.averageHRV))ms")
                        .font(.calmCaption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            MrFizzView(stressLevel: vm.currentStress, size: 52)
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var mainChartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("HRV Over Time")
                .font(.calmHeadline)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            HRVChartView(readings: vm.readings, showColorDots: true)
                .frame(height: 180)
                .padding(Spacing.md)
        }
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var barChartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Daily Averages")
                .font(.calmHeadline)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            BarChartView(data: vm.weeklyData, barColor: .calmPink)
                .frame(height: 150)
                .padding(Spacing.md)
        }
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var scatterCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Level Breakdown")
                .font(.calmHeadline)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            LevelBreakdownView(readings: vm.readings)
                .frame(height: 120)
                .padding(Spacing.md)
        }
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

struct LevelBreakdownView: View {
    let readings: [HRVReading]

    var breakdown: [(StressLevel, Int)] {
        var counts: [StressLevel: Int] = [:]
        for r in readings { counts[r.stressLevel, default: 0] += 1 }
        return StressLevel.allCases.map { ($0, counts[$0] ?? 0) }
    }

    var totalReadings: Int { readings.count }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.md) {
            ForEach(breakdown, id: \.0) { (level, count) in
                VStack(spacing: 4) {
                    Text("\(count)")
                        .font(.calmCaption2)
                        .foregroundStyle(.secondary)
                    let pct = totalReadings > 0 ? Double(count) / Double(totalReadings) : 0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(level.color)
                        .frame(height: max(4, 80 * pct))
                    Text(String(level.rawValue.prefix(3)))
                        .font(.calmCaption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ChartsView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
