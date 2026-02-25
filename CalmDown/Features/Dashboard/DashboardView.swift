import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showingSleepDetail = false
    @State private var showingWatchFaces  = false
    @AppStorage("userName") private var userName = "Alex"

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.calmLightBlue, Color.calmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection

                        // Mr. Fizz Character
                        mrFizzSection

                        // HRV mini card
                        hrvMiniCard

                        // Timeline
                        if !vm.hrvReadings.isEmpty {
                            timelineSection
                        }

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingWatchFaces = true
                    } label: {
                        Image(systemName: "applewatch")
                            .foregroundStyle(Color.calmMint)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSleepDetail = true
                    } label: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color.calmLavender)
                    }
                }
            }
        }
        .task { await vm.loadData() }
        .sheet(isPresented: $showingSleepDetail) {
            SleepView()
        }
        .sheet(isPresented: $showingWatchFaces) {
            WatchFacesView()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hi \(userName),")
                .font(.calmTitle3)
                .foregroundStyle(.secondary)
            Text("here's your daily score")
                .font(.calmLargeTitle)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mr. Fizz
    private var mrFizzSection: some View {
        VStack(spacing: Spacing.md) {
            MrFizzView(stressLevel: vm.stressLevel, size: 180)
                .padding(.top, Spacing.sm)

            if vm.isLoading {
                ProgressView()
                    .tint(Color.calmBlue)
                    .padding(.vertical, Spacing.sm)
            } else if vm.hasData {
                // Real data
                HStack(spacing: Spacing.sm) {
                    Text(vm.stressLevel.rawValue)
                        .font(.calmTitle2)
                        .foregroundStyle(vm.stressLevel.color)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(Int(vm.currentHRV))ms HRV")
                        .font(.calmTitle2)
                        .foregroundStyle(.primary)
                }
                StressGaugeView(stressLevel: vm.stressLevel, hrv: vm.currentHRV)
                    .frame(height: 20)
                    .padding(.horizontal, Spacing.xl)
            } else {
                // No data from Apple Watch yet
                VStack(spacing: Spacing.xs) {
                    Text("No HRV data yet")
                        .font(.calmCallout)
                        .foregroundStyle(.secondary)
                    Text("Wear your Apple Watch for a few minutes")
                        .font(.calmCaption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .liquidGlass(cornerRadius: CornerRadius.xl)
    }

    // MARK: - HRV Mini Card
    private var hrvMiniCard: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HRV")
                    .font(.calmCaption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(vm.hasData ? "\(Int(vm.currentHRV))" : "—")
                        .font(.calmMetricLG)
                    if vm.hasData {
                        Text("ms")
                            .font(.calmSubheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: vm.trendArrow)
                        .font(.caption)
                    Text(vm.stressLevel.description)
                        .font(.calmCaption2)
                        .lineLimit(2)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            if vm.hrvReadings.count > 3 {
                HRVChartView(readings: Array(vm.hrvReadings.suffix(12)), showColorDots: true)
                    .frame(width: 140, height: 80)
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Timeline
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today's Timeline")
                .font(.calmHeadline)
                .foregroundStyle(.primary)

            LazyVStack(spacing: 2) {
                ForEach(vm.hrvReadings.suffix(8).reversed()) { reading in
                    TimelineRowView(reading: reading)
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

struct TimelineRowView: View {
    let reading: HRVReading

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(reading.stressLevel.color)
                .frame(width: 10, height: 10)

            Text(reading.timestamp.shortTimeString)
                .font(.calmCaption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            Text(reading.stressLevel.rawValue)
                .font(.calmBody)
                .foregroundStyle(reading.stressLevel.color)

            Spacer()

            Text("\(Int(reading.value))ms")
                .font(.calmCallout)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

#Preview {
    DashboardView()
}
