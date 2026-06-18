import WidgetKit
import SwiftUI

extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        return self.contentMarginsDisabled()
    }
}
