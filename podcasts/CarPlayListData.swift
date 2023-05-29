import CarPlay
import Foundation

final class CarPlayListData {
    typealias SectionDataSource = () -> [CPListSection]?

    private var dataSource: SectionDataSource
    private let emptyTitle: String

    /// Track whether we need to refresh the data source
    /// fileprivate on purpose to allow it to only be used by the template extension below
    fileprivate var needsUpdate = true

    init(emptyTitle: String, _ dataSource: @escaping SectionDataSource) {
        self.emptyTitle = emptyTitle
        self.dataSource = dataSource
    }

    /// Refresh the given template data from the dataSource
    func reloadData(_ template: CPListTemplate) {
        template.emptyViewSubtitleVariants = [emptyTitle]

        // If the data returned is missing, don't update
        guard let data = dataSource() else { return }
        template.updateSections(data)
    }

    /// Creates a new `CPListTemplate` with a data source attached to it
    static func template(title: String, emptyTitle: String, image: UIImage? = nil, _ dataSource: @escaping SectionDataSource) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        template.tabTitle = title
        template.tabImage = image
        template.emptyViewSubtitleVariants = [L10n.loading]
        template.userInfo = CarPlayListData(emptyTitle: emptyTitle, dataSource)
        return template
    }

    /// Creates a new `CPListTemplate` that doesn't update
    static func staticTemplate(title: String, image: UIImage? = nil, _ dataSource: @escaping SectionDataSource) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: dataSource() ?? [])
        template.tabTitle = title
        template.tabImage = image
        return template
    }
}

// MARK: - Template Reloading

extension CPTemplate {
    /// Will reloadData if needed
    func didAppear() {
        guard let dataSource = userInfo as? CarPlayListData else { return }

        if dataSource.needsUpdate {
            reloadData()
        }

        dataSource.needsUpdate = false
    }

    /// Tracks whether the data needs to be updated on appear
    func didDisappear() {
        guard let dataSource = userInfo as? CarPlayListData else { return }
        dataSource.needsUpdate = true
    }

    /// Refresh the data for the template if possible
    func reloadData() {
        guard let list = self as? CPListTemplate, let dataSource = userInfo as? CarPlayListData else {
            return
        }

        dataSource.reloadData(list)
    }
}
