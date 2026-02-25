import SwiftUI

struct SleepView: View {
    @StateObject private var vm = SleepViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmNavy.ignoresSafeArea()
                starsBackground

                if vm.isLoading {
                    loadingView
                } else if let sleep = vm.sleepData {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.lg) {
                            sleepRingSection(sleep: sleep)
                            statsRow(sleep: sleep)
                            stagesCard(sleep: sleep)
                            heartRateCard
                            Spacer(minLength: Spacing.xxl)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.lg)
                    }
                } else {
                    noDataView
                }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .task { await vm.loadData() }
    }

    // MARK: - Empty / Loading states

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(.white)
            Text("Loading sleep data…")
                .font(.calmBody)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var noDataView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.calmLavender)
            Text("No Sleep Data")
                .font(.calmTitle2)
                .foregroundStyle(.white)
            Text("Make sure you wear your Apple Watch to bed and have sleep tracking enabled in the Health app.")
                .font(.calmBody)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Stars background
    private var starsBackground: some View {
        GeometryReader { geo in
            ForEach(0..<80, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.6)))
                    .frame(width: Double.random(in: 1...3), height: Double.random(in: 1...3))
                    .position(
                        x: Double.random(in: 0...geo.size.width),
                        y: Double.random(in: 0...geo.size.height * 0.5)
                    )
            }
        }
    }

    // MARK: - Sleep ring
    private func sleepRingSection(sleep: SleepData) -> some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                RingProgressView(
                    progress: Double(sleep.quality.score) / 100,
                    color: .calmLavender,
                    lineWidth: 16,
                    size: 180
                )
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.calmLavender)
                    Text(sleep.quality.rawValue)
                        .font(.calmTitle2)
                        .foregroundStyle(.white)
                }
            }

            Text(sleepSummaryText(sleep: sleep))
                .font(.calmCaption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
        .padding(Spacing.lg)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    private func sleepSummaryText(sleep: SleepData) -> String {
        switch sleep.quality {
        case .excellent:
            return "Excellent sleep! Your body recovered well. You're ready to handle today's stress."
        case .good:
            return "Good sleep last night. Your HRV should be elevated this morning."
        case .fair:
            return "Fair sleep. Consider going to bed earlier and reducing screen time tonight."
        case .poor:
            return "Poor sleep detected. This can elevate stress hormones — try to rest more today."
        }
    }

    // MARK: - Stats row
    private func statsRow(sleep: SleepData) -> some View {
        HStack(spacing: Spacing.md) {
            sleepStatItem(title: "Duration", value: sleep.durationString, icon: "bed.double.fill", color: .calmLavender)
            Divider().background(Color.white.opacity(0.2))
            sleepStatItem(title: "Quality", value: sleep.quality.rawValue, icon: "star.fill", color: .yellow)
            Divider().background(Color.white.opacity(0.2))
            sleepStatItem(title: "Avg HR", value: "\(Int(sleep.averageHeartRate))bpm", icon: "heart.fill", color: .calmPink)
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func sleepStatItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body)
            Text(value)
                .font(.calmMetricSM)
                .foregroundStyle(.white)
            Text(title)
                .font(.calmCaption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stages card
    private func stagesCard(sleep: SleepData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Sleep Stages")
                .font(.calmHeadline)
                .foregroundStyle(.white)

            if sleep.stages.isEmpty {
                Text("No stage data available")
                    .font(.calmCaption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 60)
            } else {
                SleepChartView(stages: sleep.stages, heartRateData: [])
            }
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Heart rate card
    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Heart Rate During Sleep")
                .font(.calmHeadline)
                .foregroundStyle(.white)

            if vm.heartRateData.isEmpty {
                Text("No heart rate data available")
                    .font(.calmCaption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(height: 80)
            } else {
                SleepChartView(stages: [], heartRateData: vm.heartRateData)
                    .colorScheme(.dark)
            }
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

#Preview {
    SleepView()
}
