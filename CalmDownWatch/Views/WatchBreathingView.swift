import SwiftUI

struct WatchBreathingView: View {
    @State private var scale:  CGFloat = 1.0
    @State private var isIn    = true
    @State private var seconds = 4

    var body: some View {
        ZStack {
            Color.calmDeepGreen.ignoresSafeArea()

            VStack(spacing: 8) {
                ZStack {
                    ForEach(0..<2) { i in
                        Circle()
                            .fill(Color.calmMint.opacity(0.15))
                            .scaleEffect(scale + CGFloat(i) * 0.15)
                    }
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.calmMint, .calmDeepGreen],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .scaleEffect(scale)

                    VStack(spacing: 2) {
                        Text(isIn ? "In" : "Out")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(seconds)s")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: 80, height: 80)
                .onAppear { startBreathing() }

                Text(isIn ? "Breathe In" : "Breathe Out")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 4.0)) { scale = 1.3 }
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            withAnimation(.easeInOut(duration: 6.0)) { scale = 1.0 }
            isIn = false
        }
    }
}

#Preview {
    WatchBreathingView()
        .frame(width: 198, height: 242)
}
