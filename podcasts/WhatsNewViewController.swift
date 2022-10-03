import UIKit

class WhatsNewViewController: PCViewController, UIScrollViewDelegate, TinyPageControlDelegate, WhatsNewLinkDelegate {
    @IBOutlet var shadowView: ThemeableView! {
        didSet {
            if hideShadow {
                shadowView.layer.shadowRadius = 0
            } else {
                shadowView.layer.masksToBounds = false
                shadowView.layer.shadowColor = AppTheme.appearanceShadowColor().cgColor
                shadowView.layer.shadowOffset = CGSize(width: 0, height: -2)
                shadowView.layer.shadowOpacity = 0.15
                shadowView.layer.shadowRadius = 2
            }
        }
    }

    private var hideShadow = true
    @IBOutlet var nextButton: ThemeableRoundedButton!
    @IBOutlet var pageControl: TinyPageControl! {
        didSet {
            pageControl.delegate = self
            pageControl.allowPagesToLoop = false
        }
    }

    @IBOutlet var scrollView: UIScrollView! {
        didSet {
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.delegate = self
        }
    }

    @IBOutlet var shadowViewBottomConstraint: NSLayoutConstraint!
    var pages = [WhatsNewPageView]()
    var whatsNewInfo: WhatsNewInfo

    required init(whatsNewInfo: WhatsNewInfo) {
        self.whatsNewInfo = whatsNewInfo
        super.init(nibName: "WhatsNewViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("WhatsNewViewController init(coder) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.whatsNew
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(closeTapped(_:)))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        scrollView.isPagingEnabled = true
        scrollView.isDirectionalLockEnabled = true

        if Settings.whatsNewLastAcknowledged() == whatsNewInfo.versionCode, appDelegate()?.miniPlayer()?.miniPlayerShowing() ?? false {
            shadowViewBottomConstraint.constant = shadowViewBottomConstraint.constant - Constants.Values.miniPlayerOffset
        }

        setupContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Settings.whatsNewLastAcknowledged() != whatsNewInfo.versionCode {
            Settings.setWhatsNewLastAcknowledged(whatsNewInfo.versionCode)
        }
    }

    func setupContent() {
        var leadingConstraint: NSLayoutAnchor = scrollView.leadingAnchor
        var cnstraintsToActivate = [NSLayoutConstraint]()
        for newPageInfo in whatsNewInfo.pages {
            let newPage = WhatsNewPageView(pageInfo: newPageInfo, whatsNewLinkDelegate: self)
            pages.append(newPage)

            scrollView.addSubview(newPage)
            newPage.translatesAutoresizingMaskIntoConstraints = false
            cnstraintsToActivate.append(newPage.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0))
            cnstraintsToActivate.append(newPage.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0))
            cnstraintsToActivate.append(newPage.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: 0))
            cnstraintsToActivate.append(newPage.leadingAnchor.constraint(equalTo: leadingConstraint, constant: 0))
            cnstraintsToActivate.append(newPage.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0))
            leadingConstraint = newPage.trailingAnchor
        }

        cnstraintsToActivate.append(scrollView.trailingAnchor.constraint(equalTo: leadingConstraint, constant: 0))
        NSLayoutConstraint.activate(cnstraintsToActivate)

        pageControl.numberOfPages = pages.count
        pageControl.isHidden = (pages.count < 2)
        pageControl.currentPage = 0

        updateButtonText()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: view.bounds.width * CGFloat(pages.count), height: scrollView.bounds.height)
        pageDidChange(pageControl.currentPage)
    }

    @IBAction func nextTapped(_ sender: Any) {
        let nextPage = pageControl.currentPage + 1
        if nextPage <= pageControl.numberOfPages - 1 {
            let offset = CGFloat(nextPage) * scrollView.bounds.width
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
        } else {
            close()
        }
    }

    @IBAction func closeTapped(_ sender: Any) {
        close()
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    // MARK: - What's New delegate

    func closeWhatsNew() {
        close()
    }

    // MARK: - ScrollView Delegate

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let targetOffsetX = scrollView.contentOffset.x // CGFloat(targetContentOffset.pointee.x)
        let currentPage = Int(round(targetOffsetX / scrollView.frame.width))
        if currentPage == pageControl.currentPage { return }
        pageControl.currentPage = currentPage
        updateButtonText()
    }

    // MARK: - TinyPageControlDelegate

    func pageDidChange(_ newPage: Int) {
        let offset = CGFloat(pageControl.currentPage) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }

    private func updateButtonText() {
        if pageControl.currentPage == pageControl.numberOfPages - 1 {
            nextButton.setTitle(L10n.done, for: .normal)
        } else {
            nextButton.setTitle(L10n.next, for: .normal)
        }
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
