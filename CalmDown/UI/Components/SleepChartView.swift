import SwiftUI
import Charts

struct SleepChartView: View {
    let stages: [SleepStage]
    let heartRateData: [(Date, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Sleep stages bar
            if !stages.isEmpty {
                SleepStagesBar(stages: stages)
                    .frame(height: 40)

                // Legend
                HStack(spacing: Spacing.md) {
                    ForEach(SleepStage.Stage.allCases, id: \.self) { stage in
                        HStack(spacing: 4) {
                            Circle().fill(stageColor(stage)).frame(width: 8, height: 8)
                            Text(stage.rawValue).font(.calmCaption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Heart rate during sleep
            if !heartRateData.isEmpty {
                Text("Heart Rate During Sleep")
                    .font(.calmCaption)
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xs)

                Chart {
                    ForEach(heartRateData.indices, id: \.self) { idx in
                        let (date, value) = heartRateData[idx]
                        LineMark(
                            x: .value("Time", date),
                            y: .value("BPM",  value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.calmCoral, .calmPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYScale(domain: 50...100)
                .frame(height: 120)
            }
        }
    }

    private func stageColor(_ stage: SleepStage.Stage) -> Color {
        switch stage {
        case .awake: return .calmCoral.opacity(0.7)
        case .rem:   return .calmLavender
        case .core:  return .chartBlue
        case .deep:  return .calmNavy.opacity(0.7)
        }
    }
}

struct SleepStagesBar: View {
    let stages: [SleepStage]

    var totalDuration: TimeInterval {
        stages.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(stages) { stage in
                    let fraction = stage.endTime.timeIntervalSince(stage.startTime) / max(totalDuration, 1)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stageColor(stage.stage))
                        .frame(width: geo.size.width * fraction)
                }
            }
        }
    }

    private func stageColor(_ stage: SleepStage.Stage) -> Color {
        switch stage {
        case .awake: return .calmCoral.opacity(0.7)
        case .rem:   return .calmLavender
        case .core:  return .chartBlue
        case .deep:  return .calmNavy.opacity(0.7)
        }
    }
}

#Preview {
    SleepChartView(
        stages: SleepStage.mock(),
        heartRateData: []
    )
    .padding()
}
