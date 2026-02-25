import SwiftUI

struct WatchDashboardView: View {
    @State private var hrv:         Double      = 51
    @State private var stressLevel: StressLevel = .great
    @State private var heartRate:   Double      = 68
    @State private var isPulsing    = false

    var body: some View {
        ZStack {
            Color.calmDeepGreen.ignoresSafeArea()

            VStack(spacing: 6) {
                // Time + HRV label
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(timeString)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        Text("HRV")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 8)

                // Mr. Fizz character
                WatchMrFizzView(stressLevel: stressLevel, size: 60)
                    .scaleEffect(isPulsing ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)

                // Stress label
                Text("\(stressLevel.rawValue) · \(Int(hrv))ms")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(stressLevel.color)

                // Gauge
                WatchGaugeView(stressLevel: stressLevel)
                    .frame(width: 120, height: 8)
                    .padding(.horizontal, 12)

            }
        }
        .onAppear { isPulsing = true }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink {
                    WatchBreathingView()
                } label: {
                    Label("Breathe", systemImage: "wind")
                        .font(.system(size: 11))
                }
            }
        }
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: Date())
    }
}

struct WatchMrFizzView: View {
    let stressLevel: StressLevel
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(stressLevel.color.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .init(x: 0.3, y: 0.25),
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                )

            VStack(spacing: size * 0.05) {
                HStack(spacing: size * 0.18) {
                    Circle().fill(Color.black).frame(width: size * 0.12, height: size * 0.12)
                    Circle().fill(Color.black).frame(width: size * 0.12, height: size * 0.12)
                }
                if stressLevel == .great || stressLevel == .good {
                    Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: size * 0.3, height: size * 0.12)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black)
                        .frame(width: size * 0.25, height: 2.5)
                }
            }
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle:   Angle
    var clockwise:  Bool

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(
                center:     CGPoint(x: rect.midX, y: rect.midY),
                radius:     rect.width / 2,
                startAngle: startAngle,
                endAngle:   endAngle,
                clockwise:  clockwise
            )
        }
    }
}

struct WatchGaugeView: View {
    let stressLevel: StressLevel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.stressOverload, .stressHigh, .stressNormal, .stressGood, .stressGreat],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)

                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(radius: 2)
                    .offset(x: geo.size.width * stressLevel.gaugePosition - 6)
                    .animation(.spring(), value: stressLevel)
            }
        }
    }
}

#Preview {
    WatchDashboardView()
        .frame(width: 198, height: 242)
}
