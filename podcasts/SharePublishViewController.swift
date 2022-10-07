import PocketCastsDataModel
import PocketCastsServer
import UIKit

class SharePublishViewController: PCViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UITextFieldDelegate {
    private let podcastCellId = "SelectedPodcast"

    private let maxTitleLength = 100
    private let maxDescriptionLength = 500

    private let animateToMiddleTime = 0.5 as TimeInterval
    private let pauseTime = 2.0 as TimeInterval

    private let interCellPadding = 8 as CGFloat
    private let sidePadding = 16 as CGFloat
    private let podcastsPerRow = 4 as CGFloat

    private var shareBtn: UIBarButtonItem!

    private var sharingFailed = false
    private var sharingUrl = ""
    private var animationCompleted = false

    private weak var delegate: ShareListDelegate?

    @IBOutlet var nameDividerHeight: NSLayoutConstraint! {
        didSet {
            nameDividerHeight.constant = 1 / UIScreen.main.scale
        }
    }

    @IBOutlet var descriptionDividerHeight: NSLayoutConstraint! {
        didSet {
            descriptionDividerHeight.constant = 1 / UIScreen.main.scale
        }
    }

    @IBOutlet var nameDivider: ThemeDividerView!
    @IBOutlet var descriptionDivider: ThemeDividerView!

    @IBOutlet var descriptionPlaceholder: UILabel! {
        didSet {
            descriptionPlaceholder.textColor = AppTheme.placeholderTextColor()
            descriptionPlaceholder.text = L10n.podcastShareListDescription
        }
    }

    @IBOutlet var listName: UITextField! {
        didSet {
            listName.placeholder = L10n.podcastShareListName
        }
    }

    @IBOutlet var listDescription: UITextView!
    @IBOutlet var podcastCollectionView: UICollectionView! {
        didSet {
            podcastCollectionView.register(UINib(nibName: "SelectedPodcastCell", bundle: nil), forCellWithReuseIdentifier: podcastCellId)
        }
    }

    @IBOutlet var creatingView: UIView!
    @IBOutlet var creatingListLabel: ThemeableLabel!
    @IBOutlet var creatingListProgress: UIProgressView!

    @IBOutlet var creatingListProgressLabel: UILabel! {
        didSet {
            creatingListProgressLabel.text = L10n.podcastShareListCreating
        }
    }

    private var selectedPodcasts: [Podcast]

    init(podcasts: [Podcast], delegate: ShareListDelegate?) {
        selectedPodcasts = podcasts
        self.delegate = delegate

        super.init(nibName: "SharePublishViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        shareBtn = UIBarButtonItem(title: L10n.share, style: .plain, target: self, action: #selector(SharePublishViewController.shareTapped))
        shareBtn.isEnabled = false
        customRightBtn = shareBtn

        super.viewDidLoad()

        title = L10n.sharePodcastsCreateList

        navigationItem.rightBarButtonItem = shareBtn
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        listName.becomeFirstResponder()
    }

    @objc func shareTapped() {
        guard let title = listName.text else { return }

        listName.resignFirstResponder()
        listDescription.resignFirstResponder()
        shareBtn.title = L10n.sharePodcastsSharing
        shareBtn.isEnabled = false
        startSharingAnimation()

        let shareUuids = selectedPodcasts.compactMap { podcast -> String in
            podcast.uuid
        }

        Analytics.track(.sharePodcastsListPublishStarted, properties: ["count": selectedPodcasts.count])

        let listInfo = SharingServerHandler.PodcastShareInfo(title: title, description: listDescription.text, podcasts: shareUuids)
        SharingServerHandler.shared.sharePodcastList(listInfo: listInfo) { shareUrl in
            DispatchQueue.main.async {
                guard let shareUrl = shareUrl else {
                    self.sharingDidFail()

                    return
                }

                self.sharingDidSucceed(shareUrl)
            }
        }
    }

    // MARK: - Collection View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedPodcasts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: podcastCellId, for: indexPath) as! SelectedPodcastCell

        let podcast = selectedPodcasts[indexPath.row]
        cell.populateFrom(podcast)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width

        let size = (availableWidth - (sidePadding * 2) - ((podcastsPerRow - 1) * interCellPadding)) / podcastsPerRow
        let alteredSize = min(100, size)

        return CGSize(width: alteredSize, height: alteredSize)
    }

    // MARK: - Animation

    private var animatedCellSnapshots = [UIView]()
    private func startSharingAnimation() {
        for cell in podcastCollectionView.visibleCells {
            let snapshot = cell.sj_snapshot(afterScreenUpdate: false, opaque: false)
            view.addSubview(snapshot)
            snapshot.frame = view.convert(cell.frame, from: cell.superview)
            snapshot.layer.allowsEdgeAntialiasing = true

            animatedCellSnapshots.append(snapshot)
        }

        listName.isHidden = true
        nameDivider.isHidden = true
        listDescription.isHidden = true
        descriptionDivider.isHidden = true
        podcastCollectionView.isHidden = true
        descriptionPlaceholder.isHidden = true
        creatingListLabel.text = listName.text
        creatingListProgress.progress = 0
        creatingView.alpha = 0
        creatingView.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.creatingView.alpha = 1
        })
        UIView.animate(withDuration: animateToMiddleTime + pauseTime, animations: {
            self.creatingListProgress.setProgress(0.95, animated: true)
        })

        let centerX = (view.bounds.width / 2.0)
        let centerY = creatingView.frame.origin.y + (creatingView.bounds.height / 2.0) // (self.view.bounds.height / 2.0)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.animationCompleted = true
            if !self.sharingFailed, self.sharingUrl.count > 0 {
                self.sharingDidSucceed(self.sharingUrl)
            }
        }

        // loop through all the visible cells and animate them into the middle of the screen
        for (index, cell) in animatedCellSnapshots.enumerated() {
            // move to the center in a curve, then fly out
            let moveToCenterAnimation = CAKeyframeAnimation(keyPath: "position")

            let path = UIBezierPath()
            path.move(to: cell.layer.position)
            let c1X = (cell.layer.position.x + centerX) / 2.0
            let c1Y = ((cell.layer.position.y + centerY) / 2.0)
            let c1 = CGPoint(x: c1X, y: cell.layer.position.y)
            let c2 = CGPoint(x: centerX, y: c1Y)
            path.addCurve(to: CGPoint(x: centerX, y: centerY), controlPoint1: c1, controlPoint2: c2)
            moveToCenterAnimation.path = path.cgPath

            moveToCenterAnimation.duration = animateToMiddleTime
            moveToCenterAnimation.isRemovedOnCompletion = false
            moveToCenterAnimation.fillMode = CAMediaTimingFillMode.forwards
            moveToCenterAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            cell.layer.add(moveToCenterAnimation, forKey: "moveToCenter")

            // offset each one a bit to make it look more natural
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            var rotateOffset = 0 as Double
            if index % 3 == 1 {
                rotateOffset = -0.1
            } else if index % 3 == 2 {
                rotateOffset = 0.1
            }
            rotateAnimation.toValue = NSNumber(value: rotateOffset as Double)
            rotateAnimation.duration = animateToMiddleTime
            rotateAnimation.isRemovedOnCompletion = false
            rotateAnimation.fillMode = CAMediaTimingFillMode.forwards
            rotateAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            cell.layer.add(rotateAnimation, forKey: "rotateIn")
        }

        let progressAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        progressAnimation.toValue = NSNumber(value: 0 as Double)
        progressAnimation.duration = 2.0
        creatingListProgress.layer.add(progressAnimation, forKey: "pauseAnimation")
        CATransaction.commit()
    }

    private func sharingDidFail() {
        sharingFailed = true
        sharingUrl = ""
        transitionToShareFailed()

        SJUIUtils.showAlert(title: L10n.sharePodcastsSharingFailedTitle, message: L10n.sharePodcastsSharingFailedMsg, from: self)

        Analytics.track(.sharePodcastsListPublishFailed, properties: ["count": selectedPodcasts.count])
    }

    private func sharingDidSucceed(_ shareUrl: String) {
        sharingFailed = false
        sharingUrl = shareUrl
        if animationCompleted {
            transitionToShareCompleted()
        }
    }

    private func transitionToShareFailed() {
        removeAllAnimatedCells()

        if listDescription.text.count == 0 {
            descriptionPlaceholder.isHidden = false
        }
        podcastCollectionView.isHidden = false
        listName.isHidden = false
        nameDivider.isHidden = false
        listDescription.isHidden = false
        descriptionDivider.isHidden = false
        creatingView.isHidden = true
        shareBtn.isEnabled = true
        shareBtn.title = L10n.retry
    }

    private func transitionToShareCompleted() {
        guard let name = listName.text else { return }
        Analytics.track(.sharePodcastsListPublishSucceeded, properties: ["count": selectedPodcasts.count])

        dismiss(animated: true) {
            self.removeAllAnimatedCells()
            self.delegate?.shareUrlAvailable(self.sharingUrl, listName: name)
        }
    }

    private func removeAllAnimatedCells() {
        creatingView.isHidden = true

        for view in animatedCellSnapshots {
            view.layer.removeAllAnimations()
            view.removeFromSuperview()
        }

        animatedCellSnapshots.removeAll()
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }

        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= maxTitleLength
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidStart)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.textEditingDidEnd)
    }

    // MARK: - UITextViewDelegate

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }

        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= maxDescriptionLength
    }

    func textViewDidChange(_ textView: UITextView) {
        descriptionPlaceholder.isHidden = textView.text.count > 0
    }

    @IBAction func nameDidChange(_ sender: AnyObject) {
        let name = listName.text == nil ? "" : listName.text!

        shareBtn.isEnabled = name.count > 0
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
}
