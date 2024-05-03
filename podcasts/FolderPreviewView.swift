import PocketCastsDataModel
import UIKit

class FolderPreviewView: UIView {
    private let previewCount = 4
    private let interPreviewPadding: CGFloat = 4

    private let imageSizeRatio: CGFloat = 120 / 44
    private let imageSizeRatioNoLabel: CGFloat = 120 / 48

    var showFolderName = true

    var forCarPlay = false

    private var images: [PodcastImageView] = []
    private var gradientLayer: CAGradientLayer?
    private var nameLabel: UILabel?
    private var nameLabelBottomConstraint: NSLayoutConstraint?

    func populateFrom(folder: Folder) {
        let podcastUuids = DataManager.sharedManager.allPodcastsInFolder(folder: folder).map(\.uuid)
        setup(folderName: folder.name, folderColor: folder.color, topPodcastUuids: podcastUuids)
    }

    func populateFrom(model: FolderModel) {
        setup(folderName: model.nameForFolder(), folderColor: Int32(model.colorInt), topPodcastUuids: model.selectedPodcastUuids)
    }

    private func setup(folderName: String, folderColor: Int32, topPodcastUuids: [String]) {
        cleanupImages()
        configureGradient()
        updateNameLabel(name: folderName)
        accessibilityLabel = folderName.isEmpty ? L10n.folderUnnamed : "\(folderName) \(L10n.folder)"
        isAccessibilityElement = true

        backgroundColor = AppTheme.folderColor(colorInt: folderColor)

        if folderName.isEmpty { showFolderName = false }

        for i in 0 ... (previewCount - 1) {
            let imageView: PodcastImageView
            if i < images.count {
                imageView = images[i]
            } else {
                imageView = PodcastImageView()
                addSubview(imageView)
                images.append(imageView)
            }

            if let uuid = topPodcastUuids[safe: i] {
                setImage(in: imageView, for: uuid)
            }
        }

        layoutTiles()
    }

    private func setImage(in imageView: PodcastImageView, for uuid: String) {
        if forCarPlay {
            // For CarPlay we just want to grab whatever we have in cache
            imageView.imageView?.image = ImageManager.sharedManager.cachedImageFor(podcastUuid: uuid, size: .list)
        } else {
            imageView.setPodcast(uuid: uuid, size: .list)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = bounds
        layoutTiles()
    }

    private func updateNameLabel(name: String) {
        if nameLabel == nil {
            nameLabel = UILabel()
            if let label = nameLabel {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 1
                label.textColor = UIColor.white
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                addSubview(label)

                nameLabelBottomConstraint = bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: trailingAnchor),
                    nameLabelBottomConstraint!
                ])
            }
        }

        nameLabel?.text = name
        nameLabel?.isHidden = !showFolderName
    }

    private func cleanupImages() {
        images.forEach { imageView in
            imageView.setTransparentNoArtwork(size: .list)
        }
    }

    private func configureGradient() {
        if gradientLayer != nil { return }

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.2).cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.insertSublayer(gradient, at: 0)

        gradientLayer = gradient
    }

    private func layoutTiles() {
        let tileSize = bounds.width / (showFolderName ? imageSizeRatio : imageSizeRatioNoLabel)
        let tilesPerRow = previewCount / 2
        let tileSquareSpaceNeeded = (tileSize * CGFloat(tilesPerRow)) + (interPreviewPadding * CGFloat(tilesPerRow - 1))
        let leadingOffset = (bounds.width - tileSquareSpaceNeeded) / 2
        let topOffset = showFolderName ? leadingOffset / 2 : leadingOffset

        nameLabelBottomConstraint?.constant = topOffset < 6 ? 1 : 4

        for (index, image) in images.enumerated() {
            let firstRow = index < tilesPerRow
            let rowIndex = firstRow ? CGFloat(index) : CGFloat(index - tilesPerRow)
            let x = (rowIndex * tileSize) + (rowIndex * interPreviewPadding) + leadingOffset
            let y = firstRow ? topOffset : (tileSize + interPreviewPadding + topOffset)
            image.frame = CGRect(x: x, y: y, width: tileSize, height: tileSize)
        }
    }
}
