import SwiftUI

extension Font {
    static let calmLargeTitle  = Font.system(.largeTitle,  design: .default).bold()
    static let calmTitle       = Font.system(.title,       design: .default).bold()
    static let calmTitle2      = Font.system(.title2,      design: .default).bold()
    static let calmTitle3      = Font.system(.title3,      design: .default).bold()
    static let calmHeadline    = Font.system(.headline,    design: .default)
    static let calmSubheadline = Font.system(.subheadline, design: .default)
    static let calmBody        = Font.system(.body,        design: .default)
    static let calmCallout     = Font.system(.callout,     design: .default)
    static let calmCaption     = Font.system(.caption,     design: .default)
    static let calmCaption2    = Font.system(.caption2,    design: .default)

    // Metric numbers – big rounded
    static let calmMetricXL = Font.system(size: 48, weight: .bold, design: .rounded)
    static let calmMetricLG = Font.system(size: 36, weight: .bold, design: .rounded)
    static let calmMetricMD = Font.system(size: 28, weight: .bold, design: .rounded)
    static let calmMetricSM = Font.system(size: 20, weight: .semibold, design: .rounded)
}
