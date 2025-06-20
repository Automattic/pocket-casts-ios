
class TranscriptContainerViewController: UIViewController {
    private let playbackManager: TranscriptPlaybackManaging
    private var generatedTranscriptsPremiumOverlayShown: Bool = false

    var playButtonTapped: ((Bool) -> Void)?

    private lazy var transcriptsItem: TranscriptViewController = {
        let item = TranscriptViewController(playbackManager: playbackManager, source: .episode)
        item.view.translatesAutoresizingMaskIntoConstraints = false
        item.containerDelegate = self
        item.playButtonTapped = playButtonTapped
        return item
    }()

    private lazy var generatedTranscriptsPremiumOverlay: GeneratedTranscriptsPremiumOverlay = {
        let item = GeneratedTranscriptsPremiumOverlay(playbackManager: playbackManager, analyticsSource: .episode)
        item.view.translatesAutoresizingMaskIntoConstraints = false
        item.dismissTranscript = { [weak self] in
            self?.dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: true)
        }
        item.purchaseSuccessfull = { [weak self] in
            self?.dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: false)
        }
        return item
    }()

    init(playbackManager: TranscriptPlaybackManaging) {
        self.playbackManager = playbackManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showTranscript()
        presentationController?.delegate = self
    }

    func showTranscript() {
        generatedTranscriptsPremiumOverlayShown = false

        Analytics.track(.episodeTranscriptShown)

        addChild(transcriptsItem)
        view.addSubview(transcriptsItem.view)
        transcriptsItem.view.anchorToAllSidesOf(view: view)
        transcriptsItem.didMove(toParent: self)
        transcriptsItem.willBeAddedToPlayer()
        transcriptsItem.themeDidChange()
        transcriptsItem.showGeneratedTranscriptsPremiumOverlay = { [weak self] in
            UIView.animate(withDuration: 0.25) {
                self?.showGeneratedTranscriptsPremiumOverlay()
            }
        }
    }

    private func showGeneratedTranscriptsPremiumOverlay() {
        generatedTranscriptsPremiumOverlayShown = true
        generatedTranscriptsPremiumOverlay.didAppear()
        addChild(generatedTranscriptsPremiumOverlay)
        view.addSubview(generatedTranscriptsPremiumOverlay.view)
        generatedTranscriptsPremiumOverlay.view.anchorToAllSidesOf(view: view)
        generatedTranscriptsPremiumOverlay.didMove(toParent: self)
    }

    private func dismissGeneratedTranscriptsPremiumOverlay(dismissTranscript: Bool) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.generatedTranscriptsPremiumOverlayShown = false
            self?.generatedTranscriptsPremiumOverlay.didDisappear()
            self?.generatedTranscriptsPremiumOverlay.willMove(toParent: nil)
            self?.generatedTranscriptsPremiumOverlay.removeFromParent()
            self?.generatedTranscriptsPremiumOverlay.view.removeFromSuperview()
        } completion: { [weak self] _ in
            if dismissTranscript {
                self?.dismissTranscript()
            }
        }
    }

    func hideTranscript() {
        transcriptsItem.willBeRemovedFromPlayer()
        transcriptsItem.willMove(toParent: nil)
        transcriptsItem.removeFromParent()
        transcriptsItem.view.removeFromSuperview()
        transcriptsItem.didDisappear()
    }

    private func configureTranscriptView() {
        view.backgroundColor = ThemeColor.primaryUi01()

        view.addSubview(transcriptsItem.view)
        transcriptsItem.view.anchorToAllSidesOf(view: view)
    }
}

extension TranscriptContainerViewController: PlayerItemContainerDelegate {
    func dismissTranscript() {
        dismiss(animated: true) { [weak self] in
            self?.hideTranscript()
        }
    }

    func scrollToCurrentChapter() { }
    func scrollToNowPlaying() { }
    func scrollToBookmarks() { }
    func navigateToPodcast() { }
}

extension TranscriptContainerViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) { }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if generatedTranscriptsPremiumOverlay.view.superview != nil {
            generatedTranscriptsPremiumOverlay.didDisappear()
        } else {
            hideTranscript()
        }
    }
}

extension TranscriptContainerViewController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .episodeTranscript
    }
}
