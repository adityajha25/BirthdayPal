import WidgetKit
import SwiftUI

@main
struct BirthdayPalWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        RememberedBirthdaysWidget()
        UpcomingBirthdayWidget()
    }
}
