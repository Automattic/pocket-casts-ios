import PocketCastsServer
import UIKit

extension AddCustomViewController: UICollectionViewDelegate, UICollectionViewDataSource, GridLayoutDelegate {
    func setupColorPicker() {
        let gridLayout = colorPickerView.collectionViewLayout as! GridLayout
        gridLayout.delegate = self
        gridLayout.numberOfRowsOrColumns = 1
        gridLayout.scrollDirection = .horizontal
        gridLayout.itemSpacing = 16
    }

    func colorBackgrounds() -> [UIColor] {
        var colorBackgrounds = [AppTheme.userEpisodeNoArtworkColor(), AppTheme.userEpisodeRedColor(), AppTheme.userEpisodeBlueColor(), AppTheme.userEpisodeGreenColor(),
                                AppTheme.userEpisodeYellowColor(), AppTheme.userEpisodeOrangeColor(), AppTheme.userEpisodePurpleColor(), AppTheme.userEpisodePinkColor()]

        if artwork != nil {
            colorBackgrounds.insert(AppTheme.embeddedArtworkColor(), at: 0)
            artworkIndexPath = IndexPath(item: 0, section: 0)
            greyIndexPath = IndexPath(item: 1, section: 0)
        } else {
            artworkIndexPath = nil
            greyIndexPath = IndexPath(item: 0, section: 0)
        }
        return colorBackgrounds
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colorBackgrounds().count
    }

    // MARK: - GridLayoutDelegate

    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        2
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: 40, height: 40)
    }

    // MARK: - UICollectionView Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddCustomViewController.colorCellId, for: indexPath) as! CustomStorageColorCell

        cell.setBackgroundColor(color: colorBackgrounds()[indexPath.item])
        if indexPath == artworkIndexPath {
            cell.imageView.image = artwork
            cell.imageView.contentMode = .scaleToFill
            cell.imageView.isHidden = false
        } else if indexPath == greyIndexPath {
            cell.imageView.isHidden = true
        } else {
            cell.imageView.image = UIImage(named: "locked")
            cell.imageView.contentMode = .center
            cell.imageView.isHidden = SubscriptionHelper.hasActiveSubscription()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedColorIndex = indexPath.item
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if SubscriptionHelper.hasActiveSubscription() {
            return true
        }

        if artwork != nil, indexPath.item < 2 {
            return true
        }
        showSubscriptionRequired()
        return false
    }
}
