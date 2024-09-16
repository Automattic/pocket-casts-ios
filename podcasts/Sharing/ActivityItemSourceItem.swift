class ActivityItemSourceItem: NSObject, UIActivityItemSource {
    let item: Any
    let disallowedActivityTypes: [UIActivity.ActivityType]?

    init(item: Any, disallowedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.item = item
        self.disallowedActivityTypes = disallowedActivityTypes
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard disallowedActivityTypes?.contains(where: { $0 == activityType }) != true else {
            return nil
        }
        return item
    }
}
