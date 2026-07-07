import PocketCastsDataModel
import PocketCastsUtils
import UIKit

// MARK: - Up Next tab image

extension MainTabBarController {
    /// The queue count knocked out of a continuous capsule with the "list"
    /// lines beside it, as a template image the tab bar tints like every other item.
    ///
    /// When `selected` is `true`, the capsule is fully filled and the digits
    /// are punched out as transparent cutouts so the count reads light against
    /// the tinted pill — the "active tab" counterpart to the resting badge.
    static func composeUpNextTabImage(count: Int, isSelected: Bool = false) -> UIImage? {
        let clamped = min(99, max(1, count))

        // Fixed at the widest (3-digit) size so the tab image never resizes.
        let canvasSize = CGSize(
            width: ceil(upNextBadgeLayout(count: 99, origin: .zero).size.width),
            height: 26)
        let content = upNextBadgeLayout(count: clamped, origin: .zero).size
        let origin = CGPoint(
            x: ((canvasSize.width - content.width) / 2).rounded(),
            y: ((canvasSize.height - content.height) / 2).rounded()
        )
        let layout = upNextBadgeLayout(count: clamped, origin: origin)
        let secondaryShadeAlpha: CGFloat = isSelected ? 0.45 : 0.9
        let capsuleFillAlpha: CGFloat = isSelected ? 0.93 : 0.08

        return UIGraphicsImageRenderer(size: canvasSize).image { context in
            UIColor.black.withAlphaComponent(capsuleFillAlpha).setFill()
            UIBezierPath(roundedRect: layout.capsule, cornerRadius: layout.capsule.height / 2).fill()

            let countAsStr = "\(clamped)" as NSString
            let textAttributes: [NSAttributedString.Key: Any] = [.font: layout.font, .foregroundColor: UIColor.black]
            let textSize = countAsStr.size(withAttributes: textAttributes)
            let textOrigin = CGPoint(
                x: layout.capsule.midX - textSize.width / 2,
                y: layout.capsule.midY - textSize.height / 2)
            if isSelected {
                // Punch the digits out of the filled capsule so the count reads
                // as transparent against the tinted pill.
                context.cgContext.saveGState()
                context.cgContext.setBlendMode(.destinationOut)
                countAsStr.draw(at: textOrigin, withAttributes: textAttributes)
                context.cgContext.restoreGState()
            } else {
                countAsStr.draw(at: textOrigin, withAttributes: textAttributes)
            }

            UIColor.black.withAlphaComponent(secondaryShadeAlpha).setFill()
            for line in layout.lines {
                UIBezierPath(roundedRect: line, cornerRadius: line.height / 2).fill()
            }
        }
        .withRenderingMode(.alwaysTemplate)
    }

    private struct UpNextBadgeLayout {
        let font: UIFont
        let capsule: CGRect
        let lines: [CGRect]
        let size: CGSize
    }

    private static func upNextBadgeLayout(count: Int, origin: CGPoint) -> UpNextBadgeLayout {
        let height: CGFloat = 20
        let horizontalPadding: CGFloat = 5
        let gap: CGFloat = 2
        let lineCount = 3
        // The shortest (vertically centered) line; off-center lines stretch
        // further left to track the capsule's rounded cap, see below.
        let baseLineWidth: CGFloat = 8
        let lineThickness: CGFloat = 2
        let lineSpacing: CGFloat = 4

        // Matches the full player's Up Next button (UpNextButton): 13pt for
        // 1–2 digits, 11pt once it spills to 3.
        let font = UIFont.monospacedDigitSystemFont(ofSize: count > 99 ? 11 : 13, weight: .bold)
        let textWidth = ("\(count)" as NSString).size(withAttributes: [.font: font]).width
        // A stadium shape: floor at a circle for a single digit, but let two or
        // more digits stretch into the oblong pill the design calls for.
        let capsuleWidth = max(height, (textWidth + horizontalPadding * 2).rounded())
        let capsule = CGRect(x: origin.x, y: origin.y, width: capsuleWidth, height: height)

        let linesBlockHeight = lineThickness * CGFloat(lineCount) + lineSpacing * CGFloat(lineCount - 1)
        let firstLineY = (origin.y + (height - linesBlockHeight) / 2).rounded()

        // The capsule's right end is a semicircular cap, so a line stacked
        // above or below center meets the badge further left than the middle
        // one does. Walk each line's start out along that arc and stretch it to
        // a shared right edge, so every line keeps the same visual gap from the
        // curved badge (middle line shortest, top and bottom longer).
        let capRadius = height / 2
        let capSpineX = capsule.maxX - capRadius
        let rightEdge = capsule.maxX + gap + baseLineWidth
        var lines: [CGRect] = []
        for index in 0..<lineCount {
            let lineY = firstLineY + CGFloat(index) * (lineThickness + lineSpacing)
            let dy = min(capRadius, abs(lineY + lineThickness / 2 - capsule.midY))
            let pillEdgeX = capSpineX + (capRadius * capRadius - dy * dy).squareRoot()
            let lineX = pillEdgeX + gap
            lines.append(CGRect(x: lineX, y: lineY, width: rightEdge - lineX, height: lineThickness))
        }

        return UpNextBadgeLayout(
            font: font,
            capsule: capsule,
            lines: lines,
            size: CGSize(width: capsuleWidth + gap + baseLineWidth, height: height)
        )
    }
}

// MARK: - Up Next "genie" add animation

extension MainTabBarController {
    static let upNextGenieViewTag = 776_611

    @objc func animateEpisodeAddedToUpNext(_ notification: Notification) {
        guard #available(iOS 26.0, *) else { return }
        guard let episodeUuid = notification.object as? String,
              let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else {
            // Nothing to animate — just keep the count current.
            DispatchQueue.main.async { [weak self] in self?.refreshUpNextTabBadge() }
            return
        }

        // Whether this was a "Play Next" (top) or "Play Last" (bottom) add, so
        // the flying badge can show the matching glyph and tint.
        let toTop = (notification.userInfo?[Constants.Notifications.upNextEpisodeAddedToTopKey] as? Bool) ?? false

        DispatchQueue.main.async { [weak self] in
            self?.playUpNextAddedGenieAnimation(for: episode, toTop: toTop)
        }
    }

    /// `true` while the iOS 26 liquid-glass tab bar is collapsed into its
    /// compact pill. There's no public "is minimized" API, but UIKit sets the
    /// bottom accessory's `tabAccessoryEnvironment` trait to `.inline` exactly
    /// while the tab bar is minimized, so we read it back off the mini player.
    var isTabBarMinimized: Bool {
        guard #available(iOS 26.0, *) else { return false }
        return bottomAccessory?.contentView.traitCollection.tabAccessoryEnvironment == .inline
    }

    func playUpNextAddedGenieAnimation(for episode: BaseEpisode, toTop: Bool) {
        // Fly the artwork into wherever the queue is represented on screen: the
        // Up Next tab when the tab bar is visible, or — when the tab bar is
        // collapsed into its pill — the mini player's now-playing artwork. Skip
        // the animation (and just keep the count current) when neither landing
        // point is on screen or another genie is already in flight.
        guard view.window != nil,
              view.viewWithTag(Self.upNextGenieViewTag) == nil,
              let targetFrame = upNextGenieTargetFrame() else {
            refreshUpNextTabBadge()
            return
        }

        let artworkSize: CGFloat = 64
        let cornerRadius: CGFloat = 14
        let target = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let start = CGPoint(x: target.x, y: targetFrame.minY - 24)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: artworkSize, height: artworkSize))
        container.tag = Self.upNextGenieViewTag
        container.center = start
        container.isUserInteractionEnabled = false
        container.layer.cornerRadius = cornerRadius
        container.layer.cornerCurve = .continuous
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowRadius = 12
        container.layer.shadowOffset = CGSize(width: 0, height: 6)

        // A plain image view, not `PodcastImageView`, which re-rounds its inner
        // image view with a circular curve and clobbers the continuous corner.
        let artwork = UIImageView(frame: container.bounds)
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = cornerRadius
        artwork.layer.cornerCurve = .continuous
        artwork.layer.borderWidth = 1
        artwork.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        ImageManager.sharedManager.loadImage(episode: episode, imageView: artwork, size: .list)
        container.addSubview(artwork)

        // A circled "Play Next" / "Play Last" glyph perched on the top-right
        // corner so the flying artwork clearly reads as "being added" — and as
        // *which* add — rather than just a floating thumbnail.
        let badge = makeUpNextAddBadge(toTop: toTop, diameter: 26)
        badge.center = CGPoint(x: container.bounds.width - 5, y: 5)
        container.addSubview(badge)

        view.addSubview(container)

        // Phase 1: pop in, hovering just above the landing point.
        container.alpha = 0
        container.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
            container.alpha = 1
            container.transform = .identity
        }, completion: { _ in
            // Phase 2: genie-suck down into it along a curve.
            self.runUpNextGenieSuck(on: container, from: start, to: target)
        })
    }

    /// A circled badge showing the add that just happened — a white "Play Next"
    /// or "Play Last" glyph and ring over the matching swipe-action tint
    /// (`support04` for Play Next, `support03` for Play Last) — sized to perch on
    /// the top-right corner of the flying artwork.
    private func makeUpNextAddBadge(toTop: Bool, diameter: CGFloat) -> UIView {
        let badge = UIView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        badge.backgroundColor = toTop ? ThemeColor.support04() : ThemeColor.support03()
        badge.layer.cornerRadius = diameter / 2
        badge.layer.borderWidth = 1.5
        badge.layer.borderColor = UIColor.white.cgColor

        let glyph = UIImage(named: toTop ? "list_playnext" : "list_playlast")?.withRenderingMode(.alwaysTemplate)
        let icon = UIImageView(image: glyph)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = badge.bounds.insetBy(dx: diameter * 0.24, dy: diameter * 0.24)
        badge.addSubview(icon)
        return badge
    }

    func runUpNextGenieSuck(on container: UIView, from start: CGPoint, to target: CGPoint) {
        let duration: CFTimeInterval = 0.32

        let path = UIBezierPath()
        path.move(to: start)
        // A subtle sideways swoop that accelerates into the tab, echoing the
        // macOS genie effect.
        let control = CGPoint(x: start.x + (target.x - start.x) * 0.5 - 28,
                              y: (start.y + target.y) / 2)
        path.addQuadCurve(to: target, controlPoint: control)

        let positionAnim = CAKeyframeAnimation(keyPath: "position")
        positionAnim.path = path.cgPath
        positionAnim.calculationMode = .cubicPaced

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 0.06

        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.0
        fadeAnim.beginTime = duration * 0.55

        let group = CAAnimationGroup()
        group.animations = [positionAnim, scaleAnim, fadeAnim]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeIn)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak container] in
            container?.removeFromSuperview()
        }
        container.layer.add(group, forKey: "upNextGenie")
        CATransaction.commit()

        // Near the end of the suck, swap in the new count so it reads as the artwork landing.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) { [weak self] in
            self?.refreshUpNextTabBadge()
        }
    }

    /// The frame the "added to Up Next" genie should fly into, in `view`'s
    /// coordinate space, or `nil` when no landing point is on screen.
    ///
    /// Normally that's the Up Next tab. When the tab bar is collapsed into its
    /// pill the tab isn't visible — but the mini player accessory still shows
    /// the now-playing episode artwork, so the genie lands on that instead.
    /// When minimized, UIKit keeps the private tab-button views laid out at
    /// their original (now hidden) positions, so a frame check alone can't tell
    /// the tab is gone — the trait-based `isTabBarMinimized` is the reliable
    /// signal.
    private func upNextGenieTargetFrame() -> CGRect? {
        let frame: CGRect?
        if isTabBarMinimized {
            // The mini player's episode artwork, still on screen in the pill.
            guard let artwork = NavigationManager.sharedManager.miniPlayer?.podcastArtwork,
                  artwork.window != nil else { return nil }
            frame = artwork.superview?.convert(artwork.frame, to: view)
        } else {
            guard !tabBar.isHidden, tabBar.alpha > 0.01, tabBar.window != nil else { return nil }
            frame = upNextTabTargetFrame(in: view)
        }

        guard let frame, !frame.isNull, frame.width > 0, frame.height > 0,
              view.bounds.contains(CGPoint(x: frame.midX, y: frame.midY)) else {
            return nil
        }
        return frame
    }

    /// The on-screen frame of the Up Next tab in `target`'s coordinate space,
    /// measured from the real (private) tab-button views so the genie lands
    /// exactly where `pulseUpNextTarget` fires. Falls back to an even split
    /// of the tab bar only when those views can't be located.
    func upNextTabTargetFrame(in target: UIView) -> CGRect? {
        if #available(iOS 26.0, *) {
            let buttons = upNextTabButtonViews()
            if let first = buttons.first {
                let frame = buttons.dropFirst().reduce(first.convert(first.bounds, to: target)) {
                    $0.union($1.convert($1.bounds, to: target))
                }
                if !frame.isNull, frame.width > 0, frame.height > 0 {
                    return frame
                }
            }
        }
        return upNextTabButtonFrame(in: target)
    }

    func upNextTabButtonFrame(in target: UIView) -> CGRect? {
        guard let index = pcTabs.firstIndex(of: .upNext) else { return nil }

        // Fallback: even split of the tab bar so the animation still targets
        // roughly the right place if the button view can't be located.
        let count = max(pcTabs.count, 1)
        guard tabBar.bounds.width > 0 else { return nil }
        let itemWidth = tabBar.bounds.width / CGFloat(count)
        let itemRect = CGRect(x: itemWidth * CGFloat(index), y: 0, width: itemWidth, height: tabBar.bounds.height)
        return target.convert(itemRect, from: tabBar)
    }

    /// A quick spring "pop" on whatever currently represents Up Next on screen
    /// — the tab button, or the mini player artwork when the tab bar is
    /// collapsed into its pill — so a queue change is felt, not just silently
    /// re-rendered.
    @available(iOS 26.0, *)
    func pulseUpNextTarget() {
        // A burst of rapid adds shouldn't stack overlapping springs — one pop
        // already conveys "queue grew".
        guard !isPulsingUpNextTarget else { return }

        let targets: [UIView]
        if isTabBarMinimized {
            // The tab is hidden inside the pill; pop the mini player artwork.
            guard let artwork = NavigationManager.sharedManager.miniPlayer?.podcastArtwork,
                  artwork.window != nil else { return }
            targets = [artwork]
        } else {
            targets = upNextTabButtonViews()
        }
        guard !targets.isEmpty else { return }

        isPulsingUpNextTarget = true
        Self.playUpNextPopAnimation(on: targets) { [weak self] in
            self?.isPulsingUpNextTarget = false
        }
    }

    /// A snappy, bounce-free grow, then a single softly springy settle. The
    /// grow is short enough that the peak isn't visibly held, and one gentle
    /// bounce on the way back reads as lively rather than jittery. Shared by the
    /// Up Next tab button and the mini player artwork so both react identically.
    @available(iOS 26.0, *)
    static func playUpNextPopAnimation(on views: [UIView], completion: (() -> Void)? = nil) {
        UIView.animate(springDuration: 0.15, bounce: 0, initialSpringVelocity: 0,
                       options: [.allowUserInteraction]) {
            views.forEach { $0.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) }
        } completion: { _ in
            UIView.animate(springDuration: 0.45, bounce: 0.28, initialSpringVelocity: 0,
                           options: [.allowUserInteraction]) {
                views.forEach { $0.transform = .identity }
            } completion: { _ in
                completion?()
            }
        }
    }

    /// The button views for the Up Next tab slot, or empty if they can't be
    /// located.
    ///
    /// The iOS 26 liquid-glass tab bar uses private `_UITabButton` views nested
    /// well below `UITabBar`, and renders each tab more than once (a content
    /// copy plus the glass-lens copy). We walk the whole subtree, cluster the
    /// buttons into per-tab slots by horizontal position, and return every
    /// button in the Up Next slot so the overlapping copies animate together.
    private func upNextTabButtonViews() -> [UIView] {
        guard let index = pcTabs.firstIndex(of: .upNext) else { return [] }

        var buttons: [UIView] = []
        var stack = Array(tabBar.subviews)
        while let view = stack.popLast() {
            if String(describing: type(of: view)).contains("TabButton") {
                buttons.append(view)
            }
            stack.append(contentsOf: view.subviews)
        }
        guard !buttons.isEmpty else { return [] }

        let positioned = buttons
            .map { ($0, $0.convert($0.bounds, to: tabBar).midX) }
            .sorted { $0.1 < $1.1 }

        var slots: [(x: CGFloat, views: [UIView])] = []
        for (button, x) in positioned {
            if let last = slots.indices.last, abs(slots[last].x - x) < 20 {
                slots[last].views.append(button)
            } else {
                slots.append((x, [button]))
            }
        }

        if slots.indices.contains(index) {
            return slots[index].views
        }

        // Slot count doesn't line up with the tab list (e.g. a "More" tab):
        // animate whichever slot sits nearest the expected Up Next position.
        guard let expected = upNextTabButtonFrame(in: tabBar) else { return [] }
        return slots.min { abs($0.x - expected.midX) < abs($1.x - expected.midX) }?.views ?? []
    }
}
