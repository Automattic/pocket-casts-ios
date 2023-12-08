import PocketCastsServer
import PocketCastsUtils
import UIKit

class PodcastHeadingTableCell: ThemeableCell, SubscribeButtonDelegate, ExpandableLabelDelegate {
    @IBOutlet var podcastImageView: PodcastImageView! {
        didSet {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(podcastImageLongPressed(_:)))
            podcastImageView.addGestureRecognizer(longPressGesture)
        }
    }

    @IBOutlet var podcastImageHeightConstraint: NSLayoutConstraint!

    @IBOutlet var podcastName: UILabel!
    @IBOutlet var podcastCategory: ThemeableLabel! {
        didSet {
            podcastCategory.style = .primaryText02
        }
    }

    @IBOutlet var podcastDescription: ExpandableLabel! {
        didSet {
            podcastDescription.desiredLinedHeightMultiple = 1.3
            podcastDescription.delegate = self
            podcastDescription.maxLines = 3
        }
    }

    @IBOutlet var scrollTopBackgroundVIew: UIView!
    @IBOutlet var topPodcastNameSpacer: UIView!
    @IBOutlet var topAuthorSpacer: UIView!
    @IBOutlet var bottomAuthorSpacer: UIView!
    @IBOutlet var authorView: UIView!
    @IBOutlet var author: UILabel!

    @IBOutlet var linkView: UIView!
    @IBOutlet var link: UILabel! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(websiteLinkTapped))
            link.addGestureRecognizer(tapGesture)
            link.isUserInteractionEnabled = true
        }
    }

    @IBOutlet var scheduleView: UIView!
    @IBOutlet var schedule: UILabel!

    @IBOutlet var nextEpisodeView: UIView!
    @IBOutlet var nextEpisode: UILabel!

    @IBOutlet var topBackgroundView: UIView!

    @IBOutlet var topSectionView: UIView! {
        didSet {
            let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(expandButtonTapped(_:)))
            topSectionView.addGestureRecognizer(tapRecogniser)
        }
    }

    @IBOutlet var topSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet var gradientHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subscribeButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet var subscribeButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var settingsButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var contentViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet var supporterHeartView: ThemeableView! {
        didSet {
            supporterHeartView.style = .support02
        }
    }

    @IBOutlet var supporterHeart: UIImageView!
    @IBOutlet var supporterBadge: UIImageView!
    @IBOutlet var supportDetailsView: ThemeableView! {
        didSet {
            supportDetailsView.style = .primaryUi06
        }
    }

    @IBOutlet var supportMessageHeart: UIImageView!
    @IBOutlet var supportMessage: ThemeableLabel!
    @IBOutlet var supportDate: ThemeableLabel! {
        didSet {
            supportDate.style = .primaryText02
        }
    }

    @IBOutlet var supporterDateImageView: UIImageView!
    @IBOutlet var manageSupportBtn: ThemeableUIButton!

    @IBOutlet var roundedBorder: RoundedBorderView! {
        didSet {
            roundedBorder.cornerRadius = 8
            roundedBorder.getBorderColor = { ThemeColor.primaryUi05() }
            roundedBorder.layer.borderWidth = 1
        }
    }

    @IBOutlet var subscribeButton: SubscribeButton! {
        didSet {
            subscribeButton.delegate = self
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(subscribeTapHandler(gesture:)))
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(subscribeLongPressHandler(gesture:)))
            subscribeButton.addGestureRecognizer(tapGesture)
            subscribeButton.addGestureRecognizer(longPress)
        }
    }

    @IBOutlet var extraContentStackView: UIStackView!

    @IBOutlet var settingsBtn: ThemeableUIButton! {
        didSet {
            settingsBtn.style = .primaryIcon02
        }
    }

    @IBOutlet var categoryDescriptionSpacer: UIView!
    @IBOutlet var descriptionInfoSpacer: UIView!

    @IBOutlet var folderButton: ThemeableUIButton! {
        didSet {
            folderButton.style = .primaryIcon02
            folderButton.accessibilityLabel = L10n.folder
        }
    }

    @IBOutlet var supporterView: UIView!
    @IBOutlet var supporterLabel: ThemeableLabel! {
        didSet {
            supporterLabel.style = .contrast02
        }
    }

    @IBOutlet var expandButton: ExpandCollapseButton!
    private weak var delegate: PodcastActionsDelegate? {
        didSet {
            tableViewWidth = Int(delegate?.tableView().bounds.width ?? 351)
        }
    }

    private var tableViewWidth: Int = 351
    private var isAnimatingToSubscribed = false
    var buttonsEnabled: Bool = true {
        didSet {
            subscribeButton.isEnabled = buttonsEnabled
            expandButton.isEnabled = buttonsEnabled
            folderButton.isEnabled = buttonsEnabled
            settingsBtn.isEnabled = buttonsEnabled
            manageSupportBtn.isEnabled = buttonsEnabled
            link.isUserInteractionEnabled = buttonsEnabled
        }
    }

    // we don't want a selection state
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    @IBOutlet var bookmarkTabsView: UIStackView!
    private var tabsViewController: ThemedHostingController<EpisodeBookmarksTabsView>? = nil

    private func addBookmarksTabViewIfNeeded(parentController: UIViewController) {
        guard FeatureFlag.bookmarks.enabled else {
            bookmarkTabsView.removeAllSubviews()
            bookmarkTabsView.isHidden = true
            return
        }

        // Make sure the view reappears
        if let tabsViewController {
            tabsViewController.removeFromParent()
            parentController.addChild(tabsViewController)
            tabsViewController.didMove(toParent: parentController)
            return
        }

        bookmarkTabsView.removeAllSubviews()
        let controller = ThemedHostingController(rootView: EpisodeBookmarksTabsView(delegate: delegate))

        bookmarkTabsView.addArrangedSubview(controller.view)
        parentController.addChild(controller)
        controller.didMove(toParent: parentController)

        tabsViewController = controller
        bookmarkTabsView.isHidden = false
    }

    func populateFrom(tintColor: UIColor?, delegate: PodcastActionsDelegate, parentController: UIViewController) {
        self.delegate = delegate

        guard let podcast = delegate.displayedPodcast() else { return }
        podcastImageView.setPodcast(uuid: podcast.uuid, size: .page)

        let podcastBgColor = ColorManager.backgroundColorForPodcast(podcast)
        topBackgroundView.backgroundColor = ThemeColor.podcastUi03(podcastColor: podcastBgColor)
        scrollTopBackgroundVIew.backgroundColor = topBackgroundView.backgroundColor

        podcastName.text = podcast.title
        podcastCategory.text = podcast.podcastCategory?.localized(seperatingWith: \.isNewline)
        podcastDescription.setTextKeepingExistingAttributes(text: podcast.podcastDescription)

        expandButton.tintColor = ThemeColor.contrast03()
        link.textColor = tintColor

        if podcast.isPaid {
            supporterView.isHidden = false
            supporterBadge.tintColor = ThemeColor.contrast02()
            supporterView.backgroundColor = ThemeColor.podcastUi05(podcastColor: podcastBgColor)
            supporterHeart.tintColor = ThemeColor.primaryInteractive02()

            supportMessage.text = SyncManager.isUserLoggedIn() ? L10n.subscriptionsThankYou : L10n.paidPodcastSupporterOnlyMsg
            supporterLabel.text = L10n.supporter.localizedUppercase
            if let subscription = SubscriptionHelper.subscriptionForPodcast(uuid: podcast.uuid) {
                let expiryDate = Date(timeIntervalSince1970: subscription.expiryDate)
                let expiryDateStr = DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate)
                supporterDateImageView.image = UIImage(named: "support-date-calendar")
                if subscription.autoRenewing {
                    supportDate.text = L10n.nextPaymentFormat(expiryDateStr)
                    supportMessage.style = .support02
                    supportMessageHeart.tintColor = ThemeColor.support02()
                } else {
                    supportDate.text = podcast.displayableExpiryLanguage(expiryDate: expiryDate)
                    supportMessage.style = .primaryText02
                    supportMessageHeart.tintColor = ThemeColor.primaryText02()
                }
            } else {
                supportMessage.style = .primaryText02

                if SyncManager.isUserLoggedIn() {
                    supportDate.text = L10n.paidPodcastGenericError
                    manageSupportBtn.setTitle(L10n.paidPodcastManage, for: .normal)
                } else {
                    supportDate.text = L10n.paidPodcastSigninPromptTitle
                    manageSupportBtn.setTitle(L10n.signIn, for: .normal)
                    supporterBadge.image = UIImage(named: "podcast-supporter-warning")
                    supporterBadge.tintColor = ThemeColor.contrast02()
                    supporterLabel.text = L10n.paidPodcastSigninPromptMsg
                    supporterDateImageView.image = UIImage(named: "podcast-supporter-signin")
                }
            }
        }
        supportDetailsView.isHidden = !podcast.isPaid
        supporterHeartView.isHidden = !(podcast.isPaid && podcast.isSubscribed())
        supporterView.isHidden = !podcast.isPaid

        let folderImage = (podcast.folderUuid?.isEmpty ?? true) ? "folder-empty" : "folder-check"
        folderButton.setImage(UIImage(named: folderImage), for: .normal)

        if !isAnimatingToSubscribed {
            updateLayout()
            setupButtons()

            podcastImageHeightConstraint.constant = artworkSize()
            subscribeButtonTopConstraint.constant = tableViewWidth < 350 ? 131 : 151
            gradientHeightConstraint.constant = tableViewWidth < 350 ? 117 : 137
            topSectionHeightConstraint.constant = tableViewWidth < 350 ? 183 : 203
            expandButton.setExpanded(delegate.isSummaryExpanded(), animated: false)
            podcastDescription.collapsed = !delegate.isDescriptionExpanded()

            layoutIfNeeded()
        }

        delegate.podcastRatingViewModel.update(uuid: podcast.uuid)
        addRatingIfNeeded()

        addBookmarksTabViewIfNeeded(parentController: parentController)
    }

    private lazy var ratingView: UIView? = {
        guard let viewModel = self.delegate?.podcastRatingViewModel else {
            return nil
        }

        let view = StarRatingView(viewModel: viewModel)
            .frame(height: 16)
            .padding(.top, 10)
            .themedUIView

        view.backgroundColor = .clear
        return view
    }()

    private func addRatingIfNeeded() {
        // Only add the rating if it hasn't been added already
        guard
            let ratingView, ratingView.superview == nil,
            let index = podcastCategory.flatMap({
                extraContentStackView.arrangedSubviews.firstIndex(of: $0)
            })
        else {
            return
        }

        extraContentStackView.insertArrangedSubview(ratingView, at: index+1)
    }

    @objc private func podcastImageLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.refreshArtwork(fromRect: podcastImageView.frame, inView: self)
        }
    }

    private func updateLayout() {
        guard let podcast = delegate?.displayedPodcast(), let expanded = delegate?.isSummaryExpanded() else { return }

        podcastName.isHidden = !expanded
        podcastCategory.isHidden = !expanded || podcastCategory.text == nil
        podcastDescription.isHidden = !expanded

        descriptionInfoSpacer.isHidden = !expanded
        categoryDescriptionSpacer.isHidden = !expanded

        topAuthorSpacer.isHidden = !expanded
        bottomAuthorSpacer.isHidden = !expanded
        topPodcastNameSpacer.isHidden = !expanded

        if expanded, let podcastAuthor = podcast.author {
            author.text = podcastAuthor
            authorView.isHidden = false
        } else {
            authorView.isHidden = true
        }

        if expanded, let websiteUrl = podcast.podcastUrl, let host = URL(string: websiteUrl)?.host {
            if host.startsWith(string: "www.") {
                let wwwIndex = host.index(host.startIndex, offsetBy: 4)
                link.text = String(host[wwwIndex...])
            } else {
                link.text = host
            }
            linkView.isHidden = false
        } else {
            linkView.isHidden = true
        }

        if expanded, let frequency = podcast.displayableFrequency() {
            schedule.text = L10n.paidPodcastReleaseFrequencyFormat(frequency)
            scheduleView.isHidden = false
        } else {
            scheduleView.isHidden = true
        }

        if expanded, let estimatedDate = podcast.displayableNextEpisodeDate() {
            nextEpisode.text = L10n.paidPodcastNextEpisodeFormat(estimatedDate)
            nextEpisodeView.isHidden = false
        } else {
            nextEpisodeView.isHidden = true
        }

        contentView.removeConstraint(contentViewBottomConstraint)

        // When bookmarks are enabled we need to align to the tabs view with different values
        if FeatureFlag.bookmarks.enabled {
            if let bookmarkTabsView {
                if expanded {
                    contentViewBottomConstraint = NSLayoutConstraint(item: bookmarkTabsView, attribute: .top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: extraContentStackView, attribute: .bottom, multiplier: 1, constant: 16)
                } else {
                    contentViewBottomConstraint = NSLayoutConstraint(item: bookmarkTabsView, attribute: .top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topSectionView, attribute: .bottom, multiplier: 1, constant: -1)
                }
            }
        } else {
            if expanded {
                contentViewBottomConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: extraContentStackView, attribute: .bottom, multiplier: 1, constant: 0)
            } else {
                contentViewBottomConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: topSectionView, attribute: .bottom, multiplier: 1, constant: -10)
            }
        }
        contentView.addConstraint(contentViewBottomConstraint)

        roundedBorder.isHidden = nextEpisodeView.isHidden && scheduleView.isHidden && linkView.isHidden && authorView.isHidden

        let hasRating = delegate?.podcastRatingViewModel.rating != nil
        ratingView?.isHidden = !hasRating || !expanded
    }

    private func setupButtons() {
        guard let podcast = delegate?.displayedPodcast(), let _ = delegate?.isSummaryExpanded() else { return }

        subscribeButton.isSelected = podcast.isSubscribed()
        subscribeButton.accessibilityLabel = podcast.isSubscribed() ? L10n.subscribed : L10n.subscribe
        subscribeButton.setBackgroundColors()
        if subscribeButton.isSelected {
            folderButton.isHidden = !showFolderButton()
            settingsBtn.isHidden = false
            folderButton.alpha = showFolderButton() ? 1 : 0
            settingsBtn.alpha = 1
            settingsButtonTrailingConstraint.constant = 48
            subscribeButtonWidthConstraint.constant = 32
        } else {
            subscribeButtonWidthConstraint.constant = tableViewWidth < 350 ? 120 : 147
            folderButton.isHidden = true
            settingsBtn.isHidden = true
        }
        layoutIfNeeded()
    }

    private func showFolderButton() -> Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

    @IBAction func manageSupportTapped(_ sender: Any) {
        delegate?.manageSubscriptionTapped()
    }

    @IBAction func expandButtonTapped(_ sender: Any) {
        guard let delegate = delegate, expandButton.isEnabled else { return }

        toggleExpanded(delegate: delegate)
    }

    @IBAction func settingsTapped(_ sender: Any) {
        delegate?.settingsTapped()
    }

    @IBAction func folderBtnTapped(_ sender: Any) {
        delegate?.folderTapped()
    }

    @IBAction func subscribedButtonTapped(_ sender: Any) {
        subscribeButtonTapped()
    }

    func toggleExpanded(delegate: PodcastActionsDelegate) {
        let willBeExpanded = !delegate.isSummaryExpanded()
        expandButton.setExpanded(willBeExpanded)

        delegate.tableView().beginUpdates()

        delegate.setSummaryExpanded(expanded: willBeExpanded)
        extraContentStackView.alpha = willBeExpanded ? 0 : 1

        Analytics.track(.podcastScreenToggleSummary, properties: ["is_expanded": willBeExpanded])

        // on expand, wait a bit before fading in the content so it doesn't all squish
        if willBeExpanded {
            UIView.animate(withDuration: 0.2, delay: 0.10, options: [], animations: {
                self.extraContentStackView.alpha = 1
            }, completion: nil)

            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
                self.podcastImageHeightConstraint.constant = self.artworkSize()
                self.superview?.layoutIfNeeded()
            }

            updateLayout()
            superview?.layoutIfNeeded()
        } else {
            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
                self.extraContentStackView.alpha = 0
                self.podcastImageHeightConstraint.constant = self.artworkSize()
                self.updateLayout()
                self.superview?.layoutIfNeeded()
            }
        }

        delegate.tableView().endUpdates()
    }

    // MARK: - ExpandableLabelDelegate

    func willExpandLabel(_ label: ExpandableLabel) {
        delegate?.tableView().beginUpdates()
    }

    func didExpandLabel(_ label: ExpandableLabel) {
        delegate?.tableView().endUpdates()
        delegate?.setDescriptionExpanded(expanded: true)
    }

    func willCollapseLabel(_ label: ExpandableLabel) {
        delegate?.tableView().beginUpdates()
    }

    func didCollapseLabel(_ label: ExpandableLabel) {
        delegate?.tableView().endUpdates()
        delegate?.setDescriptionExpanded(expanded: false)
    }

    @objc private func websiteLinkTapped() {
        guard let website = delegate?.displayedPodcast()?.podcastUrl, let url = URL(string: website) else { return }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func artworkSize() -> CGFloat {
        let baseSize: CGFloat = tableViewWidth < 350 ? 151 : 171
        let expanded = delegate?.isSummaryExpanded() ?? false
        return expanded ? baseSize + 10 : baseSize
    }

    // MARK: - SubscribeButtonDelegate

    func subscribeButtonTapped() {
        guard let delegate = delegate, let podcast = delegate.displayedPodcast() else { return }

        if podcast.isSubscribed() {
            delegate.unsubscribe()
        } else {
            delegate.subscribe()
            animateToSubscribed()
            toggleExpanded(delegate: delegate)
        }
    }

    // MARK: - Subscribe button animation

    private func animateToSubscribed() {
        folderButton.alpha = 0
        settingsBtn.alpha = 0
        folderButton.isHidden = !showFolderButton()
        settingsBtn.isHidden = false
        subscribeButton.isHighlighted = true
        subscribeButton.setBackgroundColors()
        layoutIfNeeded()
        isAnimatingToSubscribed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.subscribeButton.isSelected = true
            self.subscribeButton.isHighlighted = false

            UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
                self.subscribeButton.setBackgroundColors()
                self.subscribeButtonWidthConstraint.constant = 32
                self.settingsButtonTrailingConstraint.constant = 48
                self.folderButton.alpha = self.showFolderButton() ? 1 : 0
                self.settingsBtn.alpha = 1
                self.layoutIfNeeded()
            }, completion: { _ in
                self.isAnimatingToSubscribed = false
                self.subscribeButton.accessibilityLabel = L10n.subscribed
            })
        }
    }

    @objc func subscribeLongPressHandler(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            subscribeButton.isHighlighted = true
            subscribeButton.setBackgroundColors()
        } else if gesture.state == .ended {
            subscribeButtonTapped()
        } else if gesture.state == .cancelled {
            subscribeButton.isHighlighted = false
            subscribeButton.setBackgroundColors()
        }
    }

    @objc func subscribeTapHandler(gesture: UITapGestureRecognizer) {
        if gesture.state == .began {
            subscribeButton.isHighlighted = true
            subscribeButton.setBackgroundColors()
        } else if gesture.state == .ended {
            subscribeButton.isHighlighted = true
            subscribeButton.setBackgroundColors()
            subscribeButtonTapped()
        } else if gesture.state == .cancelled {
            subscribeButton.isHighlighted = false
        }
    }
}
