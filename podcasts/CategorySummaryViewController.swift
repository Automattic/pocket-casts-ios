import PocketCastsServer
import UIKit

class CategorySummaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscoverSummaryProtocol {
    @IBOutlet var categoriesTable: ThemeableTable! {
        didSet {
            categoriesTable.themeStyle = .primaryUi02
        }
    }

    @IBOutlet var titleLabel: UILabel!
    private static let cellId = "CategoryCell"

    private var categories = [DiscoverCategory]()
    private weak var delegate: DiscoverDelegate?

    @IBOutlet var categoryHeightConstraint: NSLayoutConstraint!

    private let regionCode: String
    init(regionCode: String) {
        self.regionCode = regionCode

        super.init(nibName: "CategorySummaryViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        categoriesTable.register(UINib(nibName: "CategoryCell", bundle: nil), forCellReuseIdentifier: CategorySummaryViewController.cellId)
    }

    // MARK: - DiscoverSummaryProtocol

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?) {
        guard let source = item.source else { return }

        DiscoverServerHandler.shared.discoverCategories(source: source, completion: { [weak self] discoverCategories in
            DispatchQueue.main.async {
                guard let strongSelf = self, let discoverCategories = discoverCategories else { return }

                strongSelf.titleLabel.text = item.title?.localized
                strongSelf.categories = discoverCategories
                strongSelf.categoriesTable.reloadData()
                strongSelf.setTableHeight()
            }
        })
    }

    // MARK: - UITableView methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategorySummaryViewController.cellId, for: indexPath) as! CategoryCell

        let category = categories[indexPath.row]
        cell.populateFrom(category)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]

        let categoryPodcastsController = CategoryPodcastsViewController(category: category, region: regionCode)
        if let delegate = delegate {
            categoryPodcastsController.registerDiscoverDelegate(delegate)
            delegate.navController()?.pushViewController(categoryPodcastsController, animated: true)

            if let categoryId = category.id, let categoryName = category.name {
                AnalyticsHelper.openedCategory(categoryId: categoryId, region: regionCode)

                Analytics.track(.discoverCategoryShown, properties: ["name": categoryName, "region": regionCode, "id": categoryId])
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func setTableHeight() {
        let requiredHeight = categories.count > 0 ? (categories.count * 56) : 200
        categoryHeightConstraint.constant = CGFloat(requiredHeight)
    }
}
