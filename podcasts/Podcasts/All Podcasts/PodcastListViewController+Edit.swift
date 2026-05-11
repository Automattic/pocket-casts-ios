import UIKit

extension PodcastListViewController {
    func setEditingOrder(_ editing: Bool) {
        guard isEditingOrder != editing else { return }
        isEditingOrder = editing

        if editing {
            enterEditMode()
        } else {
            exitEditMode()
        }
    }

    @objc func doneEditingTapped() {
        setEditingOrder(false)
    }

    func applyEditingTreatment(to cell: UICollectionViewCell) {
        if Settings.libraryType() == .list {
            addReorderHandle(to: cell)
        } else {
            startWiggle(on: cell)
        }
    }

    func removeEditingTreatment(from cell: UICollectionViewCell) {
        removeReorderHandle(from: cell)
        stopWiggle(on: cell)
    }

    // MARK: Mode transitions

    private func enterEditMode() {
        savedLeftBarButtonItem = navigationItem.leftBarButtonItem
        savedRightBarButtonItem = customRightBtn

        navigationItem.leftBarButtonItem = nil
        customRightBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEditingTapped))

        podcastsCollectionView.dragInteractionEnabled = true

        for cell in podcastsCollectionView.visibleCells {
            applyEditingTreatment(to: cell)
        }
    }

    private func exitEditMode() {
        podcastsCollectionView.dragInteractionEnabled = false

        navigationItem.leftBarButtonItem = savedLeftBarButtonItem
        customRightBtn = savedRightBarButtonItem
        savedLeftBarButtonItem = nil
        savedRightBarButtonItem = nil

        for cell in podcastsCollectionView.visibleCells {
            removeEditingTreatment(from: cell)
        }
    }

    // MARK: Wiggle (grid)

    private static let wiggleAnimationKey = "podcasts.editingWiggle"

    private func startWiggle(on cell: UICollectionViewCell) {
        guard cell.layer.animation(forKey: Self.wiggleAnimationKey) == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [-0.022, 0.022, -0.022]
        animation.duration = 0.16
        animation.repeatCount = .infinity
        animation.timeOffset = .random(in: 0...animation.duration) // stagger so cells don't move in unison
        cell.layer.add(animation, forKey: Self.wiggleAnimationKey)
    }

    private func stopWiggle(on cell: UICollectionViewCell) {
        cell.layer.removeAnimation(forKey: Self.wiggleAnimationKey)
    }

    // MARK: Reorder handle (list)

    private static let reorderHandleTag = 0x504C5648 // "PLVH"

    private func addReorderHandle(to cell: UICollectionViewCell) {
        guard cell.contentView.viewWithTag(Self.reorderHandleTag) == nil else { return }
        let handle = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        handle.tag = Self.reorderHandleTag
        handle.tintColor = ThemeColor.primaryIcon02()
        handle.contentMode = .center
        handle.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            handle.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            handle.widthAnchor.constraint(equalToConstant: 24),
            handle.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func removeReorderHandle(from cell: UICollectionViewCell) {
        cell.contentView.viewWithTag(Self.reorderHandleTag)?.removeFromSuperview()
    }
}
