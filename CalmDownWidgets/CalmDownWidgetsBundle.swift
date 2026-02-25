import WidgetKit
import SwiftUI

@main
struct CalmDownWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HRVWidget()
        StressWidget()
        SleepWidget()
    }
}
