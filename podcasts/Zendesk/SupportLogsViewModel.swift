import Combine
import Foundation

struct SupportLogsDisplayItem: Identifiable {
    let id = UUID()
    let displayOrder: Int
    let displayName: String
    let info: String
}

class SupportLogsViewModel: ObservableObject {
    @Published var displayItems: [SupportLogsDisplayItem]
    @Published var includeDebugInfo: Bool = !UserDefaults.standard.debugOptedOut {
        willSet {
            UserDefaults.standard.debugOptedOut = includeDebugInfo
        }
    }

    // MARK: Private vars

    private let config: ZDConfig
    private let tags: SupportLogsDisplayItem

    init(_ config: ZDConfig) {
        self.config = config
        tags = SupportLogsDisplayItem(displayOrder: 0, displayName: L10n.supportLogsTags, info: config.tags.joined(separator: ", "))
        var defaultItems = [tags]
        SupportCustomField.allCases.forEach { item in
            defaultItems.append(SupportLogsDisplayItem(displayOrder: item.displayOrder, displayName: item.dispalyTitle, info: ""))
        }

        displayItems = defaultItems.sorted { $0.displayOrder < $1.displayOrder }
    }

    func fetchDisplayItems() {
        let config = config
        let tags = [tags]

        $includeDebugInfo.flatMap { includeDebugInfo -> AnyPublisher<[SupportLogsDisplayItem], Never> in
            SupportLogsViewModel.customFields(config, optOut: !includeDebugInfo, defaultItems: tags)
        }
        .eraseToAnyPublisher()
        .receive(on: RunLoop.main)
        .assign(to: &$displayItems)
    }

    private static func customFields(_ config: ZDConfig, optOut: Bool, defaultItems: [SupportLogsDisplayItem]) -> AnyPublisher<[SupportLogsDisplayItem], Never> {
        config.customFields(forDisplay: true, optOut: optOut)
            .map { fields -> [SupportLogsDisplayItem] in
                var result = defaultItems
                result.append(contentsOf: fields.map { item in
                    let field = SupportCustomField(rawValue: item.id) ?? SupportCustomField.debugLog
                    return SupportLogsDisplayItem(displayOrder: field.displayOrder, displayName: field.dispalyTitle, info: item.value.trim())
                })

                return result.sorted { $0.displayOrder < $1.displayOrder }
            }
            .eraseToAnyPublisher()
    }
}
