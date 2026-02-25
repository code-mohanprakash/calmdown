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
                        SleepMetricCard(sleep: vm.sleep, onTap: { showingSleep = true })

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
                                symbolName: "sun.max.fill"
                            )
                            SimpleMetricCard(
                                icon:       "figure.mind.and.body",
                                iconColor:  .calmLavender,
                                title:      "Mindfulness",
                                value:      "\(Int(vm.metrics.mindfulnessMinutes))",
                                unit:       "min",
                                symbolName: "leaf.fill"
                            )
                            SimpleMetricCard(
                                icon:       "figure.walk",
                                iconColor:  .calmMint,
                                title:      "Steps",
                                value:      "\(vm.metrics.stepCount.formatted())",
                                unit:       "steps",
                                symbolName: "figure.walk"
                            )
                            SimpleMetricCard(
                                icon:       "ear.fill",
                                iconColor:  .calmPink,
                                title:      "Noise Levels",
                                value:      vm.metrics.noiseLevelCategory,
                                unit:       "\(Int(vm.metrics.noiseLevel)) dB",
                                symbolName: "ear"
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
}
