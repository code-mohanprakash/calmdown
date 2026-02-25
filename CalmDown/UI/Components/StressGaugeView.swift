import SwiftUI

/// Horizontal gradient gauge showing stress level position
struct StressGaugeView: View {
    let stressLevel: StressLevel
    let hrv: Double

    @State private var thumbPosition: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                .stressOverload,
                                .stressHigh,
                                .stressNormal,
                                .stressGood,
                                .stressGreat,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 10)

                // Thumb indicator
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(x: thumbPosition(in: geo.size.width) - 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: stressLevel)
            }
        }
        .frame(height: 20)
    }

    private func thumbPosition(in totalWidth: CGFloat) -> CGFloat {
        let position = stressLevel.gaugePosition
        return totalWidth * position
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ForEach(StressLevel.allCases, id: \.self) { level in
            VStack(alignment: .leading, spacing: 4) {
                Text(level.rawValue).font(.caption)
                StressGaugeView(stressLevel: level, hrv: 45)
            }
        }
    }
    .padding()
}
