import SwiftUI

struct ActionsView: View {
    @StateObject private var vm = ActionsViewModel()
    @State private var showingSleep = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmLightBlue.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        // Sleep card (full width) — tappable
                        SleepMetricCard(sleep: vm.sleep ?? .empty, onTap: { showingSleep = true })

                        // Fitness (full width)
                        FitnessMetricCard(
                            calories:    vm.metrics.activeCalories,
                            exerciseMin: vm.metrics.exerciseMinutes,
                            standHours:  vm.metrics.standHours
                        )

                        // 2x2 grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                            SimpleMetricCard(
                                icon:       "sun.max.fill",
                                iconColor:  .yellow,
                                title:      "Daylight",
                                value:      "\(Int(vm.metrics.daylightMinutes))",
                                unit:       "min",
                                symbolName: "sun.max.fill",
                                progress:   min(vm.metrics.daylightMinutes / 30.0, 1.0),
                                goalText:   "Goal: 30 min"
                            )
                            SimpleMetricCard(
                                icon:       "figure.mind.and.body",
                                iconColor:  Color.calmLavender,
                                title:      "Mindfulness",
                                value:      "\(Int(vm.metrics.mindfulnessMinutes))",
                                unit:       "min",
                                symbolName: "leaf.fill",
                                progress:   min(vm.metrics.mindfulnessMinutes / 10.0, 1.0),
                                goalText:   "Goal: 10 min"
                            )
                            SimpleMetricCard(
                                icon:       "figure.walk",
                                iconColor:  Color.calmMint,
                                title:      "Steps",
                                value:      "\(vm.metrics.stepCount.formatted())",
                                unit:       "steps",
                                symbolName: "figure.walk",
                                progress:   min(Double(vm.metrics.stepCount) / 8000.0, 1.0),
                                goalText:   "Goal: 8,000"
                            )
                            SimpleMetricCard(
                                icon:       "ear.fill",
                                iconColor:  Color.calmPink,
                                title:      "Noise",
                                value:      vm.metrics.noiseLevelCategory,
                                unit:       "\(Int(vm.metrics.noiseLevel)) dB",
                                symbolName: "ear.fill"
                            )
                        }

                        // Heart Rate card
                        if vm.metrics.heartRate > 0 || vm.metrics.restingHeartRate > 0 {
                            MetricCardView(
                                icon: "heart.fill",
                                iconColor: .pink,
                                title: "Heart Rate",
                                content: AnyView(
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Current").font(.calmCaption2).foregroundStyle(.secondary)
                                            HStack(alignment: .bottom, spacing: 3) {
                                                Text("\(Int(vm.metrics.heartRate > 0 ? vm.metrics.heartRate : 0))")
                                                    .font(.calmMetricSM)
                                                Text("bpm").font(.calmCaption2).foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Resting").font(.calmCaption2).foregroundStyle(.secondary)
                                            HStack(alignment: .bottom, spacing: 3) {
                                                Text("\(Int(vm.metrics.restingHeartRate > 0 ? vm.metrics.restingHeartRate : 0))")
                                                    .font(.calmMetricSM)
                                                Text("bpm").font(.calmCaption2).foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(Color.pink.opacity(0.7))
                                            .symbolEffect(.pulse)
                                    }
                                )
                            )
                        }

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.loadData() }
        .sheet(isPresented: $showingSleep) { SleepView() }
    }
}

#Preview {
    ActionsView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
