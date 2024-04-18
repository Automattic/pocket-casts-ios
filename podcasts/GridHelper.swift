import Foundation

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

    private var movingIndexPath: IndexPath?

    private let spacing: CGFloat

    // MARK: - UICollectionView layout

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func configureLayout(collectionView: UICollectionView) {
        guard let flowLayout = collectionView.collectionViewLayout as? ReorderableFlowLayout else { return }

        let gridType = Settings.libraryType()
        let spacing = gridType == .list ? 0 : self.spacing

        flowLayout.minimumLineSpacing = spacing
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: spacing, left: 0, bottom: 0, right: 0)
        flowLayout.growScale = GridHelper.moveScale
        flowLayout.alphaOnPickup = GridHelper.moveAlpha
        flowLayout.growOffset = 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let gridType = Settings.libraryType()
        let spacing = gridType == .list ? 0 : self.spacing
        return spacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let gridType = Settings.libraryType()
        let spacing = gridType == .list ? 0 : self.spacing
        return spacing
    }

    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath, itemCount: Int) -> CGSize {
        let gridType = Settings.libraryType()
        let viewWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let viewHeight = collectionView.bounds.height

        if gridType == .list {
            return CGSize(width: viewWidth, height: 65)
        }

        var divideBy: CGFloat
        if viewWidth > viewHeight {
            if viewWidth > GridHelper.bigDeviceLandscapeWidth {
                divideBy = gridType == .threeByThree ? 10 : 14
            } else {
                divideBy = gridType == .threeByThree ? 5 : 7
            }
        } else {
            if viewWidth > GridHelper.bigDevicePortraitWidth {
                divideBy = gridType == .threeByThree ? 6 : 8
            } else {
                divideBy = gridType == .threeByThree ? 3 : 4
            }
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

    // MARK: - Drag and Drop

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer, from collectionView: UICollectionView, isList: Bool, containerView: UIView) {
        var location = gesture.location(in: collectionView)
        movingIndexPath = collectionView.indexPathForItem(at: location)

        if gesture.state == .began {
            if let movingIndexPath = movingIndexPath {
                collectionView.beginInteractiveMovementForItem(at: movingIndexPath)
                animatePickingUpCell(pickedUpCell(collectionView: collectionView))
            }
        } else if gesture.state == .changed {
            if isList {
                location = CGPoint(x: containerView.bounds.width / 2, y: location.y)
            }
            collectionView.updateInteractiveMovementTargetPosition(location)
        } else if gesture.state == .ended {
            collectionView.endInteractiveMovement()
            animatePuttingDownCell(pickedUpCell(collectionView: collectionView))
        } else {
            collectionView.cancelInteractiveMovement()
            animatePuttingDownCell(pickedUpCell(collectionView: collectionView))
        }
    }

    private func pickedUpCell(collectionView: UICollectionView) -> UICollectionViewCell? {
        guard let path = movingIndexPath else { return nil }

        return collectionView.cellForItem(at: path)
    }

    private func animatePickingUpCell(_ cell: UICollectionViewCell?) {
        guard let cell = cell else { return }

        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            cell.alpha = GridHelper.moveAlpha
            cell.transform = CGAffineTransform(scaleX: GridHelper.moveScale, y: GridHelper.moveScale)
        }, completion: nil)
    }

    private func animatePuttingDownCell(_ cell: UICollectionViewCell?) {
        guard let cell = cell else { return }

        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            cell.alpha = 1
            cell.transform = .identity
        }, completion: nil)
    }
}
