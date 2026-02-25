import SwiftUI

/// Activity ring clone - animated trim ring
struct RingProgressView: View {
    let progress: Double   // 0.0 – 1.0
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    init(progress: Double, color: Color = .calmMint, lineWidth: CGFloat = 10, size: CGFloat = 80) {
        self.progress  = min(max(progress, 0), 1.5)
        self.color     = color
        self.lineWidth = lineWidth
        self.size      = size
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // End cap dot
            if animatedProgress > 0.02 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -(size / 2))
                    .rotationEffect(.degrees(-90 + animatedProgress * 360))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newVal in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = newVal
            }
        }
    }
}

// MARK: - Triple Activity Ring
struct ActivityRingsView: View {
    let moveProgress:     Double  // 0-1
    let exerciseProgress: Double
    let standProgress:    Double

    var body: some View {
        ZStack {
            RingProgressView(progress: standProgress,    color: .blue,    lineWidth: 9,  size: 70)
            RingProgressView(progress: exerciseProgress, color: .green,   lineWidth: 9,  size: 54)
            RingProgressView(progress: moveProgress,     color: .calmCoral, lineWidth: 9,  size: 38)
        }
    }
}

#Preview {
    ActivityRingsView(moveProgress: 0.84, exerciseProgress: 0.46, standProgress: 0.5)
        .padding()
}
