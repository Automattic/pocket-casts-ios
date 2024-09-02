class DiscoverCollectionViewController: UIViewController, UICollectionViewDelegate {

    enum Cell {
        case list

        var reuseIdentifier: String {
            switch self {
            case .list:
                "listCell"
            }
        }
    }

    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout())
    }()

    private let coordinator: DiscoverCoordinator

    init(coordinator: DiscoverCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: Cell.list.reuseIdentifier)
        view.addSubview(collectionView)
    }

    private func collectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
}

// MARK: - UICollectionViewDataSource

extension DiscoverCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.list.reuseIdentifier, for: indexPath) as! UICollectionViewListCell

        // Configure the cell with a label
        var content = cell.defaultContentConfiguration()
        content.text = L10n.discover
        cell.contentConfiguration = content

        return cell
    }
}
