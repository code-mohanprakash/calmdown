import SwiftUI
import Charts

struct HRVChartView: View {
    let readings: [HRVReading]
    let showColorDots: Bool

    @State private var animateChart = false

    init(readings: [HRVReading], showColorDots: Bool = true) {
        self.readings      = readings
        self.showColorDots = showColorDots
    }

    var body: some View {
        Chart {
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("HRV", animateChart ? reading.value : 0)
                )
                .foregroundStyle(Color.calmMint.gradient)
                .interpolationMethod(.catmullRom)

                if showColorDots {
                    PointMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("HRV", animateChart ? reading.value : 0)
                    )
                    .foregroundStyle(reading.stressLevel.color)
                    .symbolSize(40)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel { Text("\(value.as(Int.self) ?? 0)") }
            }
        }
        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateChart)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) {
                animateChart = true
            }
        }
    }
}

struct BarChartView: View {
    let data: [(Date, Double)]
    let barColor: Color

    @State private var animateChart = false

    init(data: [(Date, Double)], barColor: Color = .calmPink) {
        self.data     = data
        self.barColor = barColor
    }

    var body: some View {
        Chart {
            ForEach(data.indices, id: \.self) { idx in
                let (date, value) = data[idx]
                BarMark(
                    x: .value("Day",   date),
                    y: .value("Value", animateChart ? value : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateChart)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }
}

#Preview {
    VStack {
        HRVChartView(readings: HRVReading.mockReadings())
            .frame(height: 180)
            .padding()

        BarChartView(data: HRVAnalysisService.weeklyAverages(readings: HRVReading.mockReadings(count: 168)))
            .frame(height: 140)
            .padding()
    }
}
