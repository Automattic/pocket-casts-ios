import Combine
import PocketCastsServer
import UIKit

/// A Discover section cell. While the section's lists refresh in the background, it keeps showing the cached content
/// under a shimmer, and reloads the section once the new lists arrive.
final class DiscoverCell: UICollectionViewCell {
    private let shimmerView = DiscoverShimmerView()
    private var refreshObservation: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Not in `contentView`, which UIKit empties when it applies the content configuration.
        shimmerView.frame = bounds
        shimmerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(shimmerView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        refreshObservation = nil
        shimmerView.setShimmering(false, animated: false)
    }

    /// Shimmers while any of `sources` is refreshing, and calls `onRefreshed` once they've all finished and at least one has new content.
    func observeRefresh(of sources: [String], in handler: DiscoverServerHandler = .shared, onRefreshed: @escaping () -> Void) {
        guard !sources.isEmpty else {
            refreshObservation = nil
            shimmerView.setShimmering(false, animated: false)
            return
        }

        var lastRefreshed = handler.refreshStatus(of: sources).lastRefreshed
        updateShimmer(isRefreshing: handler.refreshStatus(of: sources).isRefreshing, animated: false)

        refreshObservation = handler.refreshChanges.sink { [weak self] in
            let status = handler.refreshStatus(of: sources)
            self?.updateShimmer(isRefreshing: status.isRefreshing, animated: true)

            if !status.isRefreshing, status.lastRefreshed != lastRefreshed {
                lastRefreshed = status.lastRefreshed
                onRefreshed()
            }
        }
    }

    private func updateShimmer(isRefreshing: Bool, animated: Bool) {
        if isRefreshing {
            bringSubviewToFront(shimmerView)
        }
        shimmerView.setShimmering(isRefreshing, animated: animated)
    }
}

extension DiscoverCellType.ItemType {
    /// The lists this section shows, as the paths they're requested with.
    func refreshableSources(replacingRegionCode replace: (String?) -> String?) -> [String] {
        switch cellType {
        case .categoriesSelector, .categoryPodcasts:
            return []
        default:
            let item = model.item
            let sources = ([item.source] + (item.sponsoredPodcasts ?? []).map(\.source)).compactMap { $0 }
            return Array(Set(sources + sources.compactMap { replace($0) }))
        }
    }
}

/// A light, translucent highlight that sweeps across the content under it.
final class DiscoverShimmerView: UIView {
    private static let animationKey = "shimmer"

    private let gradientLayer = CAGradientLayer()
    private var isShimmering = false
    private var foregroundObservation: AnyCancellable?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        alpha = 0
        isHidden = true

        gradientLayer.startPoint = CGPoint(x: 0, y: 0.4)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.6)
        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateColors()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            foregroundObservation = nil
            return
        }
        foregroundObservation = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.restartAnimation() }
        restartAnimation()
    }

    func setShimmering(_ shimmering: Bool, animated: Bool) {
        guard shimmering != isShimmering else { return }
        isShimmering = shimmering

        if shimmering {
            isHidden = false
            updateColors()
            restartAnimation()
        }

        let changes = { self.alpha = shimmering ? 1 : 0 }
        let completion = { (_: Bool) in
            if !self.isShimmering {
                self.isHidden = true
                self.gradientLayer.removeAnimation(forKey: Self.animationKey)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: changes, completion: completion)
        } else {
            changes()
            completion(true)
        }
    }

    private func updateColors() {
        let color = ThemeColor.primaryText01()
        if UIAccessibility.isReduceMotionEnabled {
            gradientLayer.colors = [color.withAlphaComponent(0.04).cgColor, color.withAlphaComponent(0.04).cgColor, color.withAlphaComponent(0.04).cgColor]
        } else {
            gradientLayer.colors = [color.withAlphaComponent(0.02).cgColor, color.withAlphaComponent(0.07).cgColor, color.withAlphaComponent(0.02).cgColor]
        }
    }

    private func restartAnimation() {
        gradientLayer.removeAnimation(forKey: Self.animationKey)
        guard isShimmering, window != nil, !UIAccessibility.isReduceMotionEnabled else { return }

        let sweep = CABasicAnimation(keyPath: "locations")
        sweep.fromValue = [-0.6, -0.3, 0]
        sweep.toValue = [1, 1.3, 1.6]
        sweep.duration = 1.4
        sweep.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let group = CAAnimationGroup()
        group.animations = [sweep]
        group.duration = 2.2
        group.repeatCount = .infinity
        gradientLayer.add(group, forKey: Self.animationKey)
    }
}
