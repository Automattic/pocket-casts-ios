import CarPlay
import Foundation

final class CarPlayListData {
    typealias SectionDataSource = () -> [CPListSection]?

    private var dataSource: SectionDataSource

    /// Track whether we need to refresh the data source
    /// fileprivate on purpose to allow it to only be used by the template extension below
    fileprivate var needsUpdate = false

    init(_ dataSource: @escaping SectionDataSource) {
        self.dataSource = dataSource
    }

    /// Refresh the given template data from the dataSource
    func reloadData(_ template: CPListTemplate) {
        // If the data returned is missing, don't update
        guard let data = dataSource() else { return }

        template.updateSections(data)
    }

    /// Creates a new `CPListTemplate` with a data source attached to it
    static func template(title: String, emptyTitle: String, image: UIImage? = nil, _ dataSource: @escaping SectionDataSource) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: dataSource() ?? [])
        template.tabTitle = title
        template.tabImage = image
        template.emptyViewSubtitleVariants = [emptyTitle]
        template.userInfo = CarPlayListData(dataSource)
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
