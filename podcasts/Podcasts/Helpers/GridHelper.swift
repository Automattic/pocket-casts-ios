import Foundation
import PocketCastsDataModel
import UIKit

class GridHelper {
    private static let bigDevicePortraitWidth: CGFloat = 600
    private static let bigDeviceLandscapeWidth: CGFloat = 900

    private static let moveScale: CGFloat = 1.05
    private static let moveAlpha: CGFloat = 0.8

    private lazy var cellSizeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .down

        return formatter
    }()

    private static let defaultSpacing: CGFloat = 6

    private let spacing: CGFloat

    // MARK: - UICollectionView layout

    init(spacing: CGFloat = GridHelper.defaultSpacing) {
        self.spacing = spacing
    }

    static func columnCount(viewWidth: CGFloat, viewHeight: CGFloat, gridType: LibraryType) -> CGFloat {
        if viewWidth > viewHeight {
            if viewWidth > bigDeviceLandscapeWidth {
                return gridType == .threeByThree ? 10 : 14
            }
            return gridType == .threeByThree ? 5 : 7
        }
        if viewWidth > bigDevicePortraitWidth {
            return gridType == .threeByThree ? 6 : 8
        }
        return gridType == .threeByThree ? 3 : 4
    }

    static func fullScreenPortraitCellWidth(screenSize: CGSize, gridType: LibraryType) -> CGFloat {
        let width = min(screenSize.width, screenSize.height)
        let height = max(screenSize.width, screenSize.height)
        let columns = columnCount(viewWidth: width, viewHeight: height, gridType: gridType)
        return (width - defaultSpacing * (columns - 1)) / columns
    }

    func configureLayout(collectionView: UICollectionView) {
        guard let flowLayout = collectionView.collectionViewLayout as? ReorderableFlowLayout else { return }

        let gridType = Settings.libraryType
        let spacing = gridType == .list ? 0 : self.spacing
        // Blocks horizontal scrolling on the collection view
        collectionView.contentSize.width = collectionView.bounds.width - 1
        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing * 2, left: 0, bottom: 0, right: 0)
        flowLayout.growScale = GridHelper.moveScale
        flowLayout.alphaOnPickup = GridHelper.moveAlpha
        flowLayout.growOffset = 0
    }

    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath, itemCount: Int) -> CGSize {
        let gridType = Settings.libraryType
        let viewWidth = collectionView.bounds.width - collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right
        let viewHeight = collectionView.bounds.height

        let largerSizes = Set<UIContentSizeCategory>([.accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge])

        if gridType == .list {
            let metric = UIFontMetrics(forTextStyle: .title3)
            var baseSize = CGFloat(65)
            if  largerSizes.contains(collectionView.traitCollection.preferredContentSizeCategory) {
                baseSize = 85
            }
            let imageSize = max(baseSize, metric.scaledValue(for: baseSize))
            return CGSize(width: viewWidth, height: imageSize)
        }

        var divideBy = GridHelper.columnCount(viewWidth: viewWidth, viewHeight: viewHeight, gridType: gridType)

        if  largerSizes.contains(collectionView.traitCollection.preferredContentSizeCategory) {
            divideBy = ceil(divideBy * 2 / 3)
        }

        let availableWidth = viewWidth - (spacing * (divideBy-1))
        let cellWidth =  availableWidth / divideBy
        let roundedSizeStr = cellSizeFormatter.string(from: NSNumber(value: Double(cellWidth)))
        let roundedSize = roundedSizeStr?.toDouble() ?? 0
        // if there aren't enough podcasts to fill the first row, don't do anything weird
        if viewWidth > CGFloat(Double(itemCount) * roundedSize) {
            return CGSize(width: roundedSize, height: roundedSize)
        }

        let flooredSize = floor(cellWidth)
        let pixelsRemaining = Int(availableWidth - (flooredSize * divideBy))
        // if we don't need to add extra pixels to make things sit snugly together, then don't
        if pixelsRemaining == 0 {
            return CGSize(width: flooredSize, height: flooredSize)
        }

        // if we get here then the screen is not divisible in an even amount, we'll need to add more pixels
        let row = floor(CGFloat(indexPath.row) / divideBy) + 1
        let column = indexPath.row - Int((row - 1) * divideBy)

        if pixelsRemaining > column {
            return CGSize(width: flooredSize + 1, height: flooredSize)
        }

        return CGSize(width: flooredSize, height: flooredSize)
    }
}
