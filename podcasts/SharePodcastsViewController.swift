import PocketCastsDataModel
import UIKit

protocol ShareListDelegate: AnyObject {
    func shareUrlAvailable(_ shareUrl: String, listName: String)
}

class SharePodcastsViewController: PCViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let podcastCellId = "SelectPodcastCell"

    private let interCellPadding = 8 as CGFloat
    private let sidePadding = 16 as CGFloat
    private let podcastsPerRow = 4 as CGFloat

    weak var delegate: ShareListDelegate?

    @IBOutlet var selectedCount: UILabel!
    @IBOutlet var selectAllBtn: UIButton!

    @IBOutlet var podcastCollectionView: UICollectionView! {
        didSet {
            podcastCollectionView.register(UINib(nibName: "SelectPodcastCell", bundle: nil), forCellWithReuseIdentifier: podcastCellId)
        }
    }

    @IBOutlet var bottomDividerHeight: NSLayoutConstraint! {
        didSet {
            bottomDividerHeight.constant = 1.0 / UIScreen.main.scale
        }
    }

    private var podcasts = [Podcast]()
    private var selectedPodcasts = [Podcast]()
    private var nextBtn: UIBarButtonItem!

    override func viewDidLoad() {
        nextBtn = UIBarButtonItem(title: L10n.next, style: .plain, target: self, action: #selector(SharePodcastsViewController.nextTapped))
        customRightBtn = nextBtn

        super.viewDidLoad()
        title = L10n.shareSelectPodcasts
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        loadPodcasts()
        updateSelectButton()
    }

    // MARK: - Main Actions

    @objc private func nextTapped() {
        let nextPage = SharePublishViewController(podcasts: selectedPodcasts, delegate: delegate)
        navigationController?.pushViewController(nextPage, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func selectAllTapped(_ sender: AnyObject) {
        if selectedPodcasts.count == podcasts.count {
            selectedPodcasts.removeAll()
        } else {
            selectedPodcasts.removeAll()
            for podcast in podcasts {
                selectedPodcasts.append(podcast)
            }
        }

        updateSelectButton()
        podcastCollectionView.reloadData()
    }

    // MARK: - Collection View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: podcastCellId, for: indexPath) as! SelectPodcastCell

        let podcast = podcasts[indexPath.row]
        cell.populateFrom(podcast)
        let selected = selectedPodcasts.contains(podcast)
        cell.setPodcastSelected(selected, animated: false)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SelectPodcastCell else { return }

        let podcast = podcasts[indexPath.row]

        if let index = selectedPodcasts.firstIndex(of: podcast) {
            selectedPodcasts.remove(at: index)
            cell.setPodcastSelected(false, animated: true)
        } else {
            selectedPodcasts.append(podcast)
            cell.setPodcastSelected(true, animated: true)
        }

        updateSelectButton()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width

        let size = (availableWidth - (sidePadding * 2) - ((podcastsPerRow - 1) * interCellPadding)) / podcastsPerRow
        let alteredSize = min(100, size)
        return CGSize(width: alteredSize, height: alteredSize)
    }

    // MARK: - Private Helpers

    private func updateSelectButton() {
        UIView.performWithoutAnimation {
            if self.selectedPodcasts.count == self.podcasts.count {
                self.selectAllBtn.setTitle(L10n.deselectAll.localizedUppercase, for: UIControl.State())
                self.selectedCount.text = L10n.sharePodcastsAllSelected
            } else {
                self.selectAllBtn.setTitle(L10n.selectAll.localizedUppercase, for: UIControl.State())
                self.selectedCount.text = L10n.selectedCountFormat(self.selectedPodcasts.count).localizedUppercase
            }
            self.selectAllBtn.layoutIfNeeded()
        }

        nextBtn.isEnabled = selectedPodcasts.count > 0
    }

    private func loadPodcasts() {
        let loadedPodcasts = DataManager.sharedManager.allPodcastsOrderedByTitle()
        for podcast in loadedPodcasts {
            podcasts.append(podcast)
        }

        podcastCollectionView.reloadData()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
