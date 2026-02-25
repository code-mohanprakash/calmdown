import SwiftUI

struct MetricCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: AnyView
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                    Text(title)
                        .font(.calmCaption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                content
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Specific metric cards
struct SleepMetricCard: View {
    let sleep: SleepData
    var onTap: (() -> Void)? = nil

    var body: some View {
        MetricCardView(
            icon: "moon.fill",
            iconColor: .calmLavender,
            title: "Sleep",
            content: AnyView(
                Group {
                    if sleep.hasData {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Duration").font(.calmCaption2).foregroundStyle(.secondary)
                                Text(sleep.durationString).font(.calmMetricSM).foregroundStyle(.primary)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quality").font(.calmCaption2).foregroundStyle(.secondary)
                                Text(sleep.quality.rawValue).font(.calmMetricSM).foregroundStyle(Color.calmLavender)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Avg HR").font(.calmCaption2).foregroundStyle(.secondary)
                                Text("\(Int(sleep.averageHeartRate))bpm").font(.calmMetricSM).foregroundStyle(.primary)
                            }
                            RingProgressView(progress: Double(sleep.quality.score) / 100, color: .calmLavender, lineWidth: 6, size: 44)
                        }
                    } else {
                        Text("No sleep data yet — wear your Apple Watch to bed")
                            .font(.calmCaption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            ),
            onTap: onTap
        )
    }
}

struct FitnessMetricCard: View {
    let calories: Double
    let exerciseMin: Double
    let standHours: Int

    var body: some View {
        MetricCardView(
            icon: "flame.fill",
            iconColor: .calmCoral,
            title: "Fitness",
            content: AnyView(
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Move").font(.calmCaption2).foregroundStyle(.secondary)
                        Text("\(Int(calories))CAL").font(.calmMetricSM).foregroundStyle(Color.calmCoral)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exercise").font(.calmCaption2).foregroundStyle(.secondary)
                        Text("\(Int(exerciseMin))m").font(.calmMetricSM).foregroundStyle(.green)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stand").font(.calmCaption2).foregroundStyle(.secondary)
                        Text("\(standHours)h").font(.calmMetricSM).foregroundStyle(.blue)
                    }
                    ActivityRingsView(
                        moveProgress: min(calories / 600, 1.0),
                        exerciseProgress: min(exerciseMin / 30, 1.0),
                        standProgress: min(Double(standHours) / 12, 1.0)
                    )
                    .frame(width: 70, height: 70)
                }
            )
        )
    }
}

struct SimpleMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let symbolName: String

    var body: some View {
        MetricCardView(
            icon: icon,
            iconColor: iconColor,
            title: title,
            content: AnyView(
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value)
                            .font(.calmMetricSM)
                        Text(unit)
                            .font(.calmCaption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: symbolName)
                        .font(.system(size: 32))
                        .foregroundStyle(iconColor)
                }
            )
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            SleepMetricCard(sleep: .preview)
            FitnessMetricCard(calories: 846, exerciseMin: 46, standHours: 12)
            SimpleMetricCard(icon: "sun.max.fill", iconColor: .yellow, title: "Daylight", value: "40", unit: "min", symbolName: "sun.max.fill")
            SimpleMetricCard(icon: "figure.mind.and.body", iconColor: .calmLavender, title: "Mindfulness", value: "3", unit: "min", symbolName: "leaf.fill")
            SimpleMetricCard(icon: "figure.walk", iconColor: .calmMint, title: "Steps", value: "3,000", unit: "steps", symbolName: "figure.walk")
            SimpleMetricCard(icon: "ear.fill", iconColor: .calmPink, title: "Noise Levels", value: "Normal", unit: "dB", symbolName: "ear")
        }
        .padding()
    }
}
