import SwiftUI

struct WatchFacesView: View {
    @State private var selectedFace:  Int   = 0
    @State private var selectedColor: Color = .calmMint

    let characters: [WatchCharacter] = WatchCharacter.catalog
    let colorOptions: [Color] = [.calmMint, .calmPink, .calmLavender, .calmCoral, .blue, .yellow]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.calmCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Watch mockup
                        watchMockup

                        // Character gallery
                        characterGallery

                        // Color palette
                        colorPicker

                        // Widget shortcuts
                        widgetGrid

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                }
            }
            .navigationTitle("Watch Faces")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Watch mockup
    private var watchMockup: some View {
        ZStack {
            // Watch body
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [.black, Color(hex: "#1C1C1E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 240)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

            // Watch screen content
            VStack(spacing: 4) {
                Text("FRI 23")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Text("10:09")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let char = characters[safe: selectedFace] {
                    Text(char.emoji)
                        .font(.system(size: 44))

                    Text(char.stressLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(char.stressColor)
                }

                StressGaugeView(stressLevel: .overload, hrv: 12)
                    .frame(width: 120, height: 12)
            }
            .frame(width: 160, height: 200)
        }
    }

    // MARK: - Character gallery
    private var characterGallery: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Choose Character")
                .font(.calmHeadline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(characters.indices, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.4)) { selectedFace = i }
                        } label: {
                            CharacterThumbnail(
                                character: characters[i],
                                isSelected: selectedFace == i
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Color picker
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Color")
                .font(.calmHeadline)

            HStack(spacing: Spacing.md) {
                ForEach(colorOptions.indices, id: \.self) { i in
                    Circle()
                        .fill(colorOptions[i])
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: selectedColor == colorOptions[i] ? 3 : 0)
                        )
                        .shadow(color: colorOptions[i].opacity(0.4), radius: 6)
                        .onTapGesture {
                            withAnimation(.spring()) { selectedColor = colorOptions[i] }
                        }
                }
            }
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }

    // MARK: - Widget grid
    private var widgetGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Widgets")
                .font(.calmHeadline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(WidgetPreview.samples) { widget in
                    WidgetPreviewCard(widget: widget)
                }
            }
        }
    }
}

// MARK: - Supporting types
struct WatchCharacter: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let stressLabel: String
    let stressColor: Color

    static let catalog: [WatchCharacter] = [
        WatchCharacter(name: "Bear",    emoji: "🐻",  stressLabel: "Normal",  stressColor: .stressNormal),
        WatchCharacter(name: "Cat",     emoji: "😸",  stressLabel: "Great",   stressColor: .stressGreat),
        WatchCharacter(name: "Frog",    emoji: "🐸",  stressLabel: "Good",    stressColor: .stressGood),
        WatchCharacter(name: "Chick",   emoji: "🐥",  stressLabel: "Great",   stressColor: .stressGreat),
        WatchCharacter(name: "Ghost",   emoji: "👻",  stressLabel: "Normal",  stressColor: .stressNormal),
        WatchCharacter(name: "Bunny",   emoji: "🐰",  stressLabel: "Good",    stressColor: .stressGood),
        WatchCharacter(name: "Pig",     emoji: "🐷",  stressLabel: "Overload",stressColor: .stressOverload),
        WatchCharacter(name: "Fox",     emoji: "🦊",  stressLabel: "High",    stressColor: .stressHigh),
    ]
}

struct CharacterThumbnail: View {
    let character: WatchCharacter
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(character.emoji)
                .font(.system(size: 36))
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(isSelected ? Color.calmMint.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.calmMint : Color.clear, lineWidth: 2)
                )
            Text(character.name)
                .font(.calmCaption2)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

struct WidgetPreview: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color

    static let samples: [WidgetPreview] = [
        WidgetPreview(title: "HRV",    value: "67 ms",  icon: "heart.fill",        color: .calmMint),
        WidgetPreview(title: "BHR",    value: "62 bpm", icon: "heart.circle.fill",  color: .calmPink),
        WidgetPreview(title: "Stress", value: "18.2",   icon: "bolt.fill",          color: .stressNormal),
        WidgetPreview(title: "Sleep",  value: "7.3 h",  icon: "moon.fill",          color: .calmLavender),
    ]
}

struct WidgetPreviewCard: View {
    let widget: WidgetPreview

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: widget.icon)
                .foregroundStyle(widget.color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.title)
                    .font(.calmCaption2)
                    .foregroundStyle(.secondary)
                Text(widget.value)
                    .font(.calmMetricSM)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    WatchFacesView()
        .environmentObject(StoreKitService.shared)
}
