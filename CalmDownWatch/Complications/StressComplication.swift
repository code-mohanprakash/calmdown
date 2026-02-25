import ClockKit
import SwiftUI

final class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Configuration
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "HRVComplication",
                displayName: "HRV Stress",
                supportedFamilies: [
                    .modularSmall,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicBezel,
                ]
            )
        ]
        handler(descriptors)
    }

    // MARK: - Timeline
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let entry = createEntry(for: complication, hrv: 51, stress: "Great")
        handler(entry)
    }

    private func createEntry(for complication: CLKComplication, hrv: Double, stress: String) -> CLKComplicationTimelineEntry? {
        let date = Date()

        switch complication.family {
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularView(
                HRVComplicationView(hrv: hrv, stress: stress)
            )
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerTextView(
                textProvider: CLKSimpleTextProvider(text: "\(Int(hrv))ms"),
                label: HRVCornerView(hrv: hrv)
            )
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)

        default:
            return nil
        }
    }
}

// MARK: - Complication Views
struct HRVComplicationView: View {
    let hrv: Double
    let stress: String

    var body: some View {
        ZStack {
            Circle().fill(stressColor.opacity(0.2))
            VStack(spacing: 0) {
                Text("\(Int(hrv))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("ms")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }

    var stressColor: Color {
        switch stress {
        case "Great":    return .green
        case "Good":     return Color(hex: "#8BC34A")
        case "Normal":   return .yellow
        case "High":     return .orange
        default:         return .red
        }
    }
}

struct HRVCornerView: View {
    let hrv: Double

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: hrv / 100)
                .stroke(Color.green, lineWidth: 3)
                .rotationEffect(.degrees(-90))
            Text("💚")
                .font(.system(size: 10))
        }
    }
}
