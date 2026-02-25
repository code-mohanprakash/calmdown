import SwiftUI

struct SleepView: View {
    @StateObject private var vm = SleepViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark navy background with stars
                Color.calmNavy.ignoresSafeArea()
                starsBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Circular sleep quality ring
                        sleepRingSection

                        // Stats row
                        statsRow

                        // Stage chart
                        stagesCard

                        // Heart rate chart
                        heartRateCard

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
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

    // MARK: - Subviews
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

    private var sleepRingSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Multiple rings
                RingProgressView(
                    progress: Double(vm.sleepData.quality.score) / 100,
                    color: .calmLavender,
                    lineWidth: 16,
                    size: 180
                )

                VStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.calmLavender)
                    Text(vm.sleepData.quality.rawValue)
                        .font(.calmTitle2)
                        .foregroundStyle(.white)
                }
            }

            Text("You've reached your sleep goal and your sleep quality is great. Keep it up! You're waking up fully recharged, ready to take the day ahead and handle any stress with ease.")
                .font(.calmCaption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
        }
        .padding(Spacing.lg)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            sleepStatItem(title: "Duration", value: vm.sleepData.durationString, icon: "bed.double.fill", color: .calmLavender)
            Divider().background(Color.white.opacity(0.2))
            sleepStatItem(title: "Quality", value: vm.sleepData.quality.rawValue, icon: "star.fill", color: .yellow)
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

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Sleep Stages")
                .font(.calmHeadline)
                .foregroundStyle(.white)

            SleepChartView(stages: vm.sleepData.stages, heartRateData: [])
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Heart Rate During Sleep")
                .font(.calmHeadline)
                .foregroundStyle(.white)

            if vm.heartRateData.isEmpty {
                Text("No data available")
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
