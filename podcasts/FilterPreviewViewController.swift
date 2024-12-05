import DifferenceKit
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class FilterPreviewViewController: LargeNavBarViewController, FilterChipActionDelegate, UIScrollViewDelegate {
    weak var delegate: FilterCreatedDelegate?

    @IBOutlet var filterByLabel: ThemeableLabel! {
        didSet {
            filterByLabel.style = .primaryText02
            filterByLabel.text = L10n.filterCreateFilterBy.localizedUppercase
        }
    }

    @IBOutlet var chipCollectionView: FilterChipCollectionView! {
        didSet {
            if let layout = chipCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            chipCollectionView.cellBackgroundIsPrimaryUI01 = true
        }
    }

    @IBOutlet var instructionLabel: ThemeableLabel! {
        didSet {
            instructionLabel.style = .primaryText02
            instructionLabel.text = L10n.filterCreateInstructions
        }
    }

    @IBOutlet var addMoreLabel: ThemeableLabel! {
        didSet {
            addMoreLabel.style = .primaryText02
            addMoreLabel.text = L10n.filterCreateAddMore
        }
    }

    @IBOutlet var previewLabel: ThemeableLabel! {
        didSet {
            previewLabel.style = .primaryText02
            previewLabel.text = L10n.preview.localizedUppercase
        }
    }

    @IBOutlet var previewDividerView: ThemeDividerView!
    static let previewCellId = "EpisodePreviewCell"

    @IBOutlet var previewTable: ThemeableTable! {
        didSet {
            previewTable.register(UINib(nibName: "EpisodePreviewCell", bundle: nil), forCellReuseIdentifier: FilterPreviewViewController.previewCellId)
            previewTable.rowHeight = UITableView.automaticDimension
        }
    }

    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var filterByContainerView: UIView!
    @IBOutlet var filterByHeightContraint: NSLayoutConstraint!
    @IBOutlet var previewContainerView: UIView!
    @IBOutlet var previewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var continueButton: ThemeableRoundedButton! {
        didSet {
            continueButton.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
            continueButton.setTitle(L10n.continue, for: .normal)
        }
    }

    @IBOutlet var noEpisodeView: UIView!
    @IBOutlet var noEpisodeImage: ThemeableImageView! {
        didSet {
            noEpisodeImage.imageNameFunc = AppTheme.emptyFilterImageName
        }
    }

    @IBOutlet var noEpisodesLabel: ThemeableLabel! {
        didSet {
            noEpisodesLabel.text = L10n.filterCreateNoEpisodes
        }
    }

    @IBOutlet var noEpisodeCriteriaLabel: ThemeableLabel! {
        didSet {
            noEpisodeCriteriaLabel.style = .primaryText02
            noEpisodeCriteriaLabel.text = FeatureFlag.useFollowNaming.enabled ? L10n.filterCreateNoEpisodesDescriptionExplanationNew : L10n.filterCreateNoEpisodesDescriptionExplanation
        }
    }

    @IBOutlet var noEpisodeDifferentLabel: ThemeableLabel! {
        didSet {
            noEpisodeDifferentLabel.style = .primaryText02
            noEpisodeDifferentLabel.text = L10n.filterCreateNoEpisodesDescriptionPrompt
        }
    }

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    var episodes = [ListEpisode]()
    var cellHeights: [IndexPath: CGFloat] = [:]

    var newFilter: EpisodeFilter!
    var continueToPreview = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.createFilter
        newFilter = PlaylistManager.createNewFilter()

        setupLargeTitle()
        setMinMaxNavBarHeights()

        addCloseButton()
        (view as? ThemeableView)?.style = .primaryUi01
        chipCollectionView.filter = newFilter
        chipCollectionView.chipActionDelegate = self
        addCustomObserver(Constants.Notifications.filterChanged, selector: #selector(handleFilterChanged(_:)))
        addCustomObserver(Constants.Notifications.playlistTempChange, selector: #selector(handleFilterColorChanged))
        isModalInPresentation = true

        continueButton.backgroundColor = newFilter.playlistColor().withAlphaComponent(0.25)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionViewHeightConstraint.constant = chipCollectionView.collectionViewLayout.isKind(of: LeftAlignedFlowLayout.self) ? chipCollectionView.collectionViewLayout.collectionViewContentSize.height : 38
        view.layoutIfNeeded()
    }

    deinit {
        removeAllCustomObservers()
    }

    @objc func handleFilterChanged(_ notification: Notification) {
        guard let filter = notification.object as? EpisodeFilter, filter.uuid == newFilter?.uuid else {
            return
        }

        reloadFilter()
        transformToPreview()
    }

    @objc func handleFilterColorChanged() {
        reloadFilter()
    }

    @IBAction func continueTapped(_ sender: Any) {
        navigationController?.pushViewController(CreateFilterViewController(filter: newFilter, delegate: delegate), animated: true)
    }

    override func closeAction() {
        PlaylistManager.delete(filter: newFilter, fireEvent: true)
    }

    private func reloadFilter() {
        guard let reloadedFilter = DataManager.sharedManager.findFilter(uuid: newFilter.uuid) else { return }
        newFilter = reloadedFilter
        newFilter.isNew = true
        chipCollectionView.filter = reloadedFilter
        refreshEpisodes(animated: true)
        continueButton.backgroundColor = newFilter.playlistColor()
    }

    private func transformToPreview() {
        guard let flowLayout = chipCollectionView.collectionViewLayout as? UICollectionViewFlowLayout, flowLayout.scrollDirection == .vertical else { return }

        let newHorizontalLayout = UICollectionViewFlowLayout()
        newHorizontalLayout.scrollDirection = .horizontal
        chipCollectionView.setCollectionViewLayout(newHorizontalLayout, animated: false, completion: { _ in
            self.continueButton.isEnabled = true
            self.continueButton.backgroundColor = self.newFilter.playlistColor()
            self.previewLabel.isHidden = false
            self.previewDividerView.isHidden = false
            self.addMoreLabel.isHidden = false
            self.instructionLabel.isHidden = true
            self.view.setNeedsLayout()
            // The chip cllectionview height is not set till viewWillLayoutSubviews
            // is called. Allow time for that to complete
            SwiftUtils.performAfterDelayOnMainThread(0.05, closure: {
                self.chipCollectionView.scrollToLastSelected()
            })
        })
    }

    // MARK: - Chip Action Delegate

    func presentingViewController() -> UIViewController {
        self
    }

    func starredChipSelected() {
        transformToPreview()
    }

    func refreshEpisodes(animated: Bool) {
        let refreshOperation = PlaylistRefreshOperation(tableView: previewTable, filter: newFilter) { [weak self] newData in
            guard let strongSelf = self else { return }
            strongSelf.previewTable.isHidden = (newData.count == 0)
            strongSelf.noEpisodeView.isHidden = (newData.count != 0)
            if animated {
                let oldData = strongSelf.episodes
                let changeSet = StagedChangeset(source: oldData, target: newData)
                strongSelf.previewTable.reload(using: changeSet, with: .none, setData: { data in
                    strongSelf.episodes = data
                })
            } else {
                strongSelf.episodes = newData
                strongSelf.previewTable.reloadData()
            }
        }

        operationQueue.addOperation(refreshOperation)
    }

    // MARK: - Animation to hide text when the large nav bar title disappears

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setScrollState()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        setScrollState(round: true)
    }

    var maxNavBarHeight: CGFloat = 108
    var minNavBarHeight: CGFloat = 52
    private func setMinMaxNavBarHeights() {
        if let window = view.window {
            minNavBarHeight = UIUtil.statusBarHeight(in: window)
        }
        if let largeNavBarHeight = navigationController?.navigationBar.frame.height {
            maxNavBarHeight = largeNavBarHeight
        }
    }

    private func setScrollState(round: Bool = false) {
        guard let navBarHeight = navigationController?.navigationBar.frame.height else {
            return
        }
        var percentage = 1 - ((maxNavBarHeight - navBarHeight) / (maxNavBarHeight - minNavBarHeight))
        if round {
            percentage.round()
        }
        filterByLabel.alpha = percentage
        filterByHeightContraint.constant = percentage * 40
        previewContainerView.alpha = percentage
        previewContainerHeightConstraint.constant = 4 + (percentage * 77)

        filterByLabel.isHidden = percentage < 0.7
        previewLabel.isHidden = percentage < 0.7
        previewContainerView.isHidden = percentage < 0.25
    }

    override func handleThemeChanged() {
        setupLargeTitle()
        continueButton.backgroundColor = newFilter.playlistColor().withAlphaComponent(continueButton.isEnabled ? 1 : 0.25)
        continueButton.setTitleColor(ThemeColor.primaryInteractive02(), for: .normal)
        chipCollectionView.reloadData()
    }
}
