import SwiftUI
import SwiftData

struct MoodView: View {
    @StateObject private var vm = TrackingViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Water section
                waterSection

                // Emotions grid
                emotionsSection

                // Save button
                if !vm.selectedEmotions.isEmpty {
                    Button {
                        vm.saveMood(context: modelContext)
                    } label: {
                        Label("Save Mood", systemImage: "checkmark.circle.fill")
                            .font(.calmHeadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(Color.calmMint, in: RoundedRectangle(cornerRadius: CornerRadius.full))
                    }
                    .padding(.horizontal, Spacing.md)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
        }
        .background(Color.calmLightBlue.ignoresSafeArea())
        .animation(.spring(response: 0.4), value: vm.selectedEmotions.isEmpty)
        .onAppear { vm.loadTodayTotals(context: modelContext) }
    }

    // MARK: - Water
    private var waterSection: some View {
        HStack(spacing: Spacing.md) {
            // Water card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("\(vm.todayWaterMl)")
                        .font(.calmMetricLG)
                    Text("/\(vm.waterGoalMl)ml")
                        .font(.calmCallout)
                        .foregroundStyle(.secondary)
                }
                waterWaveIcon
                Button {
                    withAnimation(.spring()) { vm.addWater(100, context: modelContext) }
                } label: {
                    Label("+100", systemImage: "plus")
                        .font(.calmCaption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: CornerRadius.md)

            // Caffeine card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .bottom) {
                    Text("\(vm.todayCaffeineMg)")
                        .font(.calmMetricLG)
                    Text("mg")
                        .font(.calmCallout)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
                coffeeIcon
                Button {
                    withAnimation(.spring()) { vm.addCaffeine(100, context: modelContext) }
                } label: {
                    Label("+100", systemImage: "plus")
                        .font(.calmCaption)
                        .foregroundStyle(.brown)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.brown.opacity(0.1), in: Capsule())
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: CornerRadius.md)
        }
    }

    private var waterWaveIcon: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.5))
                .frame(width: 50, height: 50 * vm.waterProgress)
        }
        .overlay(
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .font(.title2)
        )
        .frame(width: 50, height: 50)
    }

    private var coffeeIcon: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 36))
            .foregroundStyle(Color.brown.opacity(0.7))
    }

    // MARK: - Caffeine
    private var caffeineSection: some View {
        EmptyView() // merged into waterSection
    }

    // MARK: - Emotions
    private var emotionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Emotional State")
                .font(.calmHeadline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.md
            ) {
                ForEach(Emotion.catalog) { emotion in
                    EmotionCell(
                        emotion: emotion,
                        isSelected: vm.selectedEmotions.contains(emotion.name)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            vm.toggleEmotion(emotion.name)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

struct EmotionCell: View {
    let emotion: Emotion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emotion.emoji)
                    .font(.system(size: 28))
                Text(emotion.name)
                    .font(.calmCaption2)
                    .foregroundStyle(isSelected ? Color.calmMint : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(isSelected ? Color.calmMint.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .strokeBorder(isSelected ? Color.calmMint : Color.clear, lineWidth: 1.5)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoodView()
        .modelContainer(for: [MoodEntry.self, HydrationEntry.self], inMemory: true)
}
