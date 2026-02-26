import SwiftUI
import SwiftData

struct MoodView: View {
    @StateObject private var vm = TrackingViewModel()
    @Environment(\.modelContext) private var modelContext

    // Custom input alerts
    @State private var showCustomWater    = false
    @State private var showCustomCaffeine = false
    @State private var customWaterText    = ""
    @State private var customCaffeineText = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    intakeSection
                    emotionsSection
                    energySection
                    triggersSection
                    noteSection

                    // Save button
                    if !vm.selectedEmotions.isEmpty {
                        Button {
                            withAnimation(.spring()) {
                                vm.saveMood(context: modelContext)
                                vm.loadRecentMoods(context: modelContext)
                            }
                        } label: {
                            Label("Save Check-in", systemImage: "checkmark.circle.fill")
                                .font(.calmHeadline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.calmBlue, in: RoundedRectangle(cornerRadius: CornerRadius.full))
                        }
                        .padding(.horizontal, Spacing.md)
                        .transition(.scale.combined(with: .opacity))
                    }

                    moodHistorySection

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
            .background(Color.calmCream.ignoresSafeArea())
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.large)
        }
        .animation(.spring(response: 0.4), value: vm.selectedEmotions.isEmpty)
        .onAppear {
            vm.loadTodayTotals(context: modelContext)
            vm.loadRecentMoods(context: modelContext)
        }
        // Custom water alert
        .alert("Add Water", isPresented: $showCustomWater) {
            TextField("Amount in ml", text: $customWaterText)
                .keyboardType(.numberPad)
            Button("Add") {
                if let amount = Int(customWaterText), amount > 0 {
                    withAnimation(.spring()) { vm.addWater(amount, context: modelContext) }
                }
                customWaterText = ""
            }
            Button("Cancel", role: .cancel) { customWaterText = "" }
        } message: {
            Text("Enter a custom water amount (ml)")
        }
        // Custom caffeine alert
        .alert("Add Caffeine", isPresented: $showCustomCaffeine) {
            TextField("Amount in mg", text: $customCaffeineText)
                .keyboardType(.numberPad)
            Button("Add") {
                if let amount = Int(customCaffeineText), amount > 0 {
                    withAnimation(.spring()) { vm.addCaffeine(amount, context: modelContext) }
                }
                customCaffeineText = ""
            }
            Button("Cancel", role: .cancel) { customCaffeineText = "" }
        } message: {
            Text("Enter a custom caffeine amount (mg)")
        }
    }

    // MARK: - Intake (Water + Caffeine)
    private var intakeSection: some View {
        HStack(spacing: Spacing.md) {
            waterCard
            caffeineCard
        }
    }

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon + goal row
            HStack(spacing: Spacing.xs) {
                waterFillIcon
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Water")
                        .font(.calmCaption2)
                        .foregroundStyle(.secondary)
                    Text("Goal \(vm.waterGoalMl)ml")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            // Current value — scales down if large
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(vm.todayWaterMl)")
                    .font(.calmMetricSM)
                    .foregroundStyle(Color.blue)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("ml")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            ProgressView(value: min(vm.waterProgress, 1.0))
                .tint(vm.waterProgress >= 1.0 ? .green : .blue)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            // Quick-add buttons + custom
            HStack(spacing: Spacing.xs) {
                ForEach([100, 250, 500], id: \.self) { amount in
                    Button {
                        withAnimation(.spring()) { vm.addWater(amount, context: modelContext) }
                    } label: {
                        Text("+\(amount)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
                Button {
                    showCustomWater = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.08), in: Capsule())
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var caffeineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon + label row
            HStack(spacing: Spacing.xs) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.brown.opacity(0.75))
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Caffeine")
                        .font(.calmCaption2)
                        .foregroundStyle(.secondary)
                    Text("Limit \(vm.caffeineGoalMg)mg")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            // Current value
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(vm.todayCaffeineMg)")
                    .font(.calmMetricSM)
                    .foregroundStyle(vm.todayCaffeineMg >= vm.caffeineGoalMg ? .orange : Color.brown)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("mg")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Progress bar (orange when over limit)
            let caffeineProgress = Double(vm.todayCaffeineMg) / Double(vm.caffeineGoalMg)
            ProgressView(value: min(caffeineProgress, 1.0))
                .tint(caffeineProgress >= 1.0 ? .orange : .brown)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            // Quick-add buttons + custom
            HStack(spacing: Spacing.xs) {
                ForEach([(50, "Shot"), (100, "Coff"), (150, "Enrg")], id: \.0) { amount, label in
                    Button {
                        withAnimation(.spring()) { vm.addCaffeine(amount, context: modelContext) }
                    } label: {
                        Text("+\(amount)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.brown)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.brown.opacity(0.1), in: Capsule())
                    }
                }
                Button {
                    showCustomCaffeine = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.brown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brown.opacity(0.08), in: Capsule())
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private var waterFillIcon: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.45))
                .frame(width: 36, height: 36 * min(vm.waterProgress, 1.0))
                .animation(.spring(response: 0.5), value: vm.waterProgress)
        }
        .overlay(
            Image(systemName: "drop.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 16))
        )
        .frame(width: 36, height: 36)
    }

    // MARK: - Emotions grid
    private var emotionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("How are you feeling?")
                    .font(.calmHeadline)
                Spacer()
                if !vm.selectedEmotions.isEmpty {
                    Text("\(vm.selectedEmotions.count) selected")
                        .font(.calmCaption2)
                        .foregroundStyle(Color.calmBlue)
                }
            }

            emotionCategorySection("Positive", emotions: Emotion.catalog.filter { $0.category == .positive })
            emotionCategorySection("Neutral", emotions: Emotion.catalog.filter { $0.category == .neutral })
            emotionCategorySection("Needs Attention", emotions: Emotion.catalog.filter { $0.category == .negative })
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private func emotionCategorySection(_ label: String, emotions: [Emotion]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.calmCaption2)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.sm
            ) {
                ForEach(emotions) { emotion in
                    EmotionCell(
                        emotion: emotion,
                        isSelected: vm.selectedEmotions.contains(emotion.name)
                    ) {
                        withAnimation(.spring(response: 0.3)) { vm.toggleEmotion(emotion.name) }
                    }
                }
            }
        }
    }

    // MARK: - Energy level
    private var energySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(hex: "#FF8C00"))
                Text("Energy Level")
                    .font(.calmHeadline)
            }

            HStack(spacing: Spacing.sm) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3)) { vm.energyLevel = level }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(energyColor(level).opacity(vm.energyLevel == level ? 0.25 : 0.08))
                                    .frame(width: 44, height: 44)
                                Image(systemName: energySymbol(level))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(energyColor(level).opacity(vm.energyLevel >= level ? 1.0 : 0.3))
                            }
                            Text(energyLabel(level))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(vm.energyLevel == level ? energyColor(level) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(vm.energyLevel == level ? 1.08 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .gray
        case 2: return Color(hex: "#607D8B")
        case 3: return Color(hex: "#FFC107")
        case 4: return Color(hex: "#FF8C00")
        case 5: return Color(hex: "#4CAF50")
        default: return .gray
        }
    }

    private func energySymbol(_ level: Int) -> String {
        switch level {
        case 1: return "battery.0percent"
        case 2: return "battery.25percent"
        case 3: return "battery.50percent"
        case 4: return "battery.75percent"
        case 5: return "battery.100percent"
        default: return "battery.50percent"
        }
    }

    private func energyLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Exhausted"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Good"
        case 5: return "Energised"
        default: return "Moderate"
        }
    }

    // MARK: - Stress triggers
    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Color.calmCoral)
                Text("Stress Triggers")
                    .font(.calmHeadline)
                Text("(optional)")
                    .font(.calmCaption2)
                    .foregroundStyle(.tertiary)
            }

            FlowLayout(spacing: Spacing.sm) {
                ForEach(TrackingViewModel.triggerOptions, id: \.self) { trigger in
                    Button {
                        withAnimation(.spring(response: 0.3)) { vm.toggleTrigger(trigger) }
                    } label: {
                        Text(trigger)
                            .font(.calmCaption)
                            .foregroundStyle(vm.selectedTriggers.contains(trigger) ? .white : .primary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                vm.selectedTriggers.contains(trigger)
                                    ? AnyShapeStyle(Color.calmCoral)
                                    : AnyShapeStyle(Color.secondary.opacity(0.1)),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Mood History
    private var moodHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.calmBlue)
                Text("Recent Check-ins")
                    .font(.calmHeadline)
                Spacer()
                Text("Last 7 days")
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
            }

            if vm.recentMoods.isEmpty {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.tertiary)
                    Text("No check-ins yet — log your first mood above")
                        .font(.calmCaption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.sm)
            } else {
                ForEach(vm.recentMoods.prefix(10)) { entry in
                    MoodHistoryRow(entry: entry)
                    if entry.id != vm.recentMoods.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Note
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "pencil.line")
                    .foregroundStyle(Color.calmBlue)
                Text("Note")
                    .font(.calmHeadline)
                Text("(optional)")
                    .font(.calmCaption2)
                    .foregroundStyle(.tertiary)
            }
            TextField("What's on your mind today?", text: $vm.moodNote, axis: .vertical)
                .font(.calmBody)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

// MARK: - Mood History Row
struct MoodHistoryRow: View {
    let entry: MoodEntry

    private var energyColor: Color {
        switch entry.energyLevel {
        case 1: return .gray
        case 2: return Color(hex: "#607D8B")
        case 3: return Color(hex: "#FFC107")
        case 4: return Color(hex: "#FF8C00")
        case 5: return Color(hex: "#4CAF50")
        default: return .gray
        }
    }

    private var energyLabel: String {
        switch entry.energyLevel {
        case 1: return "Exhausted"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Good"
        case 5: return "Energised"
        default: return "Moderate"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                // Emotion name
                Text(entry.emotion)
                    .font(.calmBody)
                    .fontWeight(.medium)
                Spacer()
                // Time
                Text(entry.timestamp, style: .relative)
                    .font(.calmCaption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: Spacing.sm) {
                // Energy badge
                Label(energyLabel, systemImage: "bolt.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(energyColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(energyColor.opacity(0.12), in: Capsule())

                // Trigger chips (up to 3)
                if !entry.triggers.isEmpty {
                    ForEach(entry.triggers.split(separator: ",").prefix(3).map(String.init), id: \.self) { trigger in
                        Text(trigger)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                }
            }

            // Note if present
            if !entry.note.isEmpty {
                Text("\u{201C}\(entry.note)\u{201D}")
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .italic()
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Animated Emotion Cell (SF Symbol)
struct EmotionCell: View {
    let emotion: Emotion
    let isSelected: Bool
    let action: () -> Void
    @State private var bounced = false

    var body: some View {
        Button(action: {
            action()
            if !isSelected {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { bounced = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { bounced = false }
                }
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(emotion.color.opacity(isSelected ? 0.22 : 0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: emotion.sfSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(emotion.color)
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(bounced ? 1.25 : (isSelected ? 1.08 : 1.0))
                .shadow(color: isSelected ? emotion.color.opacity(0.3) : .clear, radius: 6)

                Text(emotion.name)
                    .font(.calmCaption2)
                    .foregroundStyle(isSelected ? emotion.color : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(isSelected ? emotion.color.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .strokeBorder(isSelected ? emotion.color : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (wrapping chip row)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        height = y + rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview {
    MoodView()
        .modelContainer(for: [MoodEntry.self, HydrationEntry.self], inMemory: true)
}
