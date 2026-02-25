import SwiftUI

struct BreathingCircleView: View {
    @Binding var phase: BreathingPhase
    let isPremium: Bool

    @State private var scale:   CGFloat = 1.0
    @State private var opacity: Double  = 0.6

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.calmMint.opacity(0.12 - Double(i) * 0.03))
                    .scaleEffect(scale + CGFloat(i) * 0.2)
                    .animation(
                        .easeInOut(duration: phase.duration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: scale
                    )
            }

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.calmMint, .calmDeepGreen],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .init(x: 0.3, y: 0.25),
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                )
                .scaleEffect(scale)
                .opacity(opacity)

            // Phase label
            VStack(spacing: 8) {
                Text(phase.label)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(phase.description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 240, height: 240)
        .onChange(of: phase) { _, newPhase in
            updateAnimation(for: newPhase)
        }
        .onAppear {
            updateAnimation(for: phase)
        }
    }

    private func updateAnimation(for phase: BreathingPhase) {
        switch phase {
        case .breatheIn:
            withAnimation(.easeInOut(duration: phase.duration)) {
                scale   = 1.3
                opacity = 1.0
            }
        case .hold:
            // Hold – no size change
            break
        case .breatheOut:
            withAnimation(.easeInOut(duration: phase.duration)) {
                scale   = 1.0
                opacity = 0.7
            }
        }
    }
}

enum BreathingPhase: CaseIterable {
    case breatheIn, hold, breatheOut

    var label: String {
        switch self {
        case .breatheIn:  return "Breathe In"
        case .hold:       return "Hold"
        case .breatheOut: return "Breathe Out"
        }
    }

    var description: String {
        switch self {
        case .breatheIn:  return "4 seconds"
        case .hold:       return "4 seconds"
        case .breatheOut: return "6 seconds"
        }
    }

    var duration: Double {
        switch self {
        case .breatheIn:  return 4.0
        case .hold:       return 4.0
        case .breatheOut: return 6.0
        }
    }

    var next: BreathingPhase {
        switch self {
        case .breatheIn:  return .hold
        case .hold:       return .breatheOut
        case .breatheOut: return .breatheIn
        }
    }
}

#Preview {
    @Previewable @State var phase = BreathingPhase.breatheIn
    ZStack {
        Color.calmNavy.ignoresSafeArea()
        BreathingCircleView(phase: $phase, isPremium: true)
    }
}
