import Foundation
import SwiftUI

struct OrderPickerToolbar<T: SortOption>: ViewModifier {
    let selectedOption: T
    let title: String
    var supportsToolbar: Bool = true
    var hasHorizontalPadding: Bool = false
    @State var presentSortOptions = false
    let didSelectOption: (T) -> Void

    func body(content: Content) -> some View {
        guard supportsToolbar else { return AnyView(content) }
        let result = content.toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentSortOptions.toggle()
                } label: {
                    EpisodeActionView(iconName: "menu_podcast_sort", title: title)
                        .padding(.leading, hasHorizontalPadding ? 0 : -8)
                }
                .padding(.vertical)
                .padding(.horizontal, hasHorizontalPadding ? nil : 0) /// `nil` will use the system default padding
                .accentColor(.background)
            }
        }
        .sheet(isPresented: $presentSortOptions) {
            OrderPickerView(selectedOption: selectedOption) { option in
                didSelectOption(option)
                presentSortOptions = false
            }
        }

        return AnyView(result)
    }
}

extension View {
    func withOrderPickerToolbar<T: SortOption>(selectedOption: T, title: String, supportsToolbar: Bool = true, hasHorizontalPadding: Bool = false, didSelectOption: @escaping (T) -> Void) -> some View {
        modifier(OrderPickerToolbar(selectedOption: selectedOption, title: title, supportsToolbar: supportsToolbar, hasHorizontalPadding: hasHorizontalPadding, didSelectOption: didSelectOption))
    }
}
