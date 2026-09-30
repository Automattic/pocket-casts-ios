import XCTest
@testable import podcasts

/// The Discover featured carousel's auto-advance: one page per tick, and none when the user asked for less motion.
@MainActor
final class FeaturedCarouselAutoScrollTests: XCTestCase {
    private let pageSize = CGSize(width: 400, height: 200)
    private let pageCount = 7

    private var window: UIWindow!
    private var collectionView: ThemeableCollectionView!
    private var dataSource: PagesDataSource!

    override func setUp() {
        super.setUp()

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = pageSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView = ThemeableCollectionView(frame: CGRect(origin: .zero, size: pageSize), collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.isAutoScrollAllowed = { true }
        dataSource = PagesDataSource(count: pageCount)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: PagesDataSource.cellId)
        collectionView.dataSource = dataSource

        window = UIWindow(frame: CGRect(origin: .zero, size: pageSize))
        window.addSubview(collectionView)
        window.makeKeyAndVisible()
        collectionView.layoutIfNeeded()
    }

    override func tearDown() {
        collectionView.stopAutoScrollTimer()
        window.isHidden = true
        window = nil
        collectionView = nil
        dataSource = nil
        super.tearDown()
    }

    func testAdvancesOnePageFromRest() {
        scroll(toPage: 3)

        collectionView.scrolltoNextItem()

        XCTAssertEqual(pageAfterScrollSettles(), 4)
    }

    func testAdvancesOnePageFromTheShownPageWhenTwoPagesArePartlyVisible() {
        let cases: [(offset: CGFloat, expectedPage: CGFloat)] = [(2.3, 3), (2.7, 4), (4.4, 5), (4.6, 6)]
        for (offset, expectedPage) in cases {
            scroll(toPage: offset)
            XCTAssertEqual(collectionView.indexPathsForVisibleItems.count, 2, "Two pages should be partly visible at page \(offset)")

            collectionView.scrolltoNextItem()

            XCTAssertEqual(pageAfterScrollSettles(), expectedPage, "Auto-advance from page \(offset) should move to the page after the one shown")
        }
    }

    func testWrapsToTheFirstPageFromTheLastPage() {
        scroll(toPage: CGFloat(pageCount - 1))

        collectionView.scrolltoNextItem()

        XCTAssertEqual(pageAfterScrollSettles(), 0)
    }

    func testDoesNotAdvanceWhenReduceMotionOrVoiceOverIsOn() {
        scroll(toPage: 3)
        collectionView.isAutoScrollAllowed = { false }

        collectionView.scrolltoNextItem()

        XCTAssertEqual(pageAfterScrollSettles(), 3)
    }

    // MARK: - Helpers

    private func scroll(toPage page: CGFloat) {
        collectionView.setContentOffset(CGPoint(x: page * pageSize.width, y: 0), animated: false)
        collectionView.layoutIfNeeded()
    }

    private func pageAfterScrollSettles() -> CGFloat {
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        return collectionView.contentOffset.x / pageSize.width
    }
}

private final class PagesDataSource: NSObject, UICollectionViewDataSource {
    static let cellId = "Page"

    let count: Int

    init(count: Int) {
        self.count = count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath)
    }
}
