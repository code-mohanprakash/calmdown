import SwiftUI

/// The animated character at the heart of CalmDown
struct MrFizzView: View {
    let stressLevel: StressLevel
    let size: CGFloat

    @State private var isPulsing  = false
    @State private var eyeBlink   = false
    @State private var blinkTask: Task<Void, Never>? = nil

    private var faceColor: Color { stressLevel.color }

    init(stressLevel: StressLevel = .great, size: CGFloat = 160) {
        self.stressLevel = stressLevel
        self.size        = size
    }

    var body: some View {
        ZStack {
            // Body (main circle)
            Circle()
                .fill(faceColor.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .init(x: 0.35, y: 0.25),
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                )
                .shadow(color: faceColor.opacity(0.4), radius: 20, x: 0, y: 8)

            // Face features
            VStack(spacing: size * 0.05) {
                // Eyes row
                HStack(spacing: size * 0.18) {
                    EyeView(size: size * 0.12, blink: eyeBlink)
                    EyeView(size: size * 0.12, blink: eyeBlink)
                }
                .offset(y: -size * 0.04)

                // Mouth / expression
                MouthView(stressLevel: stressLevel, size: size)
            }

            // Sunglasses overlay for "Great"
            if stressLevel == .great {
                SunglassesView(size: size)
                    .offset(y: -size * 0.06)
            }

            // Sweat drops for overload
            if stressLevel == .overload {
                SweatView(size: size)
            }
        }
        .scaleEffect(isPulsing ? 1.05 : 1.0)
        .animation(
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .animation(.easeInOut(duration: 0.5), value: stressLevel)
        .onAppear {
            isPulsing = true
            startBlinkTimer()
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private func startBlinkTimer() {
        blinkTask?.cancel()
        blinkTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.1)) { eyeBlink = true }
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.1)) { eyeBlink = false }
            }
        }
    }
}

// MARK: - Sub-views
struct EyeView: View {
    let size: CGFloat
    let blink: Bool

    var body: some View {
        Ellipse()
            .fill(Color.black)
            .frame(width: size, height: blink ? size * 0.1 : size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: size * 0.35, height: size * 0.35)
                    .offset(x: -size * 0.15, y: -size * 0.1)
            )
    }
}

struct MouthView: View {
    let stressLevel: StressLevel
    let size: CGFloat

    var body: some View {
        switch stressLevel {
        case .great, .good:
            // Big smile
            SmileView(size: size, flip: false)
        case .normal:
            // Neutral line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: size * 0.28, height: size * 0.04)
        case .high, .overload:
            // Frown
            SmileView(size: size, flip: true)
        }
    }
}

struct SmileView: View {
    let size: CGFloat
    let flip: Bool

    var body: some View {
        Canvas { context, canvasSize in
            let width  = canvasSize.width
            let height = canvasSize.height
            var path = Path()
            path.move(to: CGPoint(x: 0, y: flip ? 0 : height))
            path.addQuadCurve(
                to: CGPoint(x: width, y: flip ? 0 : height),
                control: CGPoint(x: width / 2, y: flip ? height * 1.5 : -height * 0.5)
            )
            context.stroke(path, with: .color(.black), lineWidth: size * 0.06)
        }
        .frame(width: size * 0.35, height: size * 0.15)
    }
}

struct SunglassesView: View {
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.04) {
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(Color.black.opacity(0.85))
                .frame(width: size * 0.22, height: size * 0.14)
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(Color.black.opacity(0.85))
                .frame(width: size * 0.22, height: size * 0.14)
        }
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: 0, y: 0)
        )
    }
}

struct SweatView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            SweatDrop(size: size * 0.12)
                .offset(x: size * 0.38, y: -size * 0.15)
                .rotationEffect(.degrees(-15))
            SweatDrop(size: size * 0.08)
                .offset(x: size * 0.32, y: size * 0.05)
                .rotationEffect(.degrees(-10))
        }
    }
}

struct SweatDrop: View {
    let size: CGFloat

    var body: some View {
        Ellipse()
            .fill(Color.blue.opacity(0.7))
            .frame(width: size * 0.6, height: size)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        ForEach(StressLevel.allCases, id: \.self) { level in
            HStack {
                MrFizzView(stressLevel: level, size: 80)
                Text(level.rawValue)
                    .font(.headline)
            }
        }
    }
    .padding()
}
