import PocketCastsServer
import PocketCastsUtils
import UIKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let statsCellId = "StatsCell"
    private let statsHeaderCellId = "StatsHeaderCell"

    private enum LoadingStatus { case loading, loaded, failed }
    private var loadingState = LoadingStatus.loading

    private var localOnly = !SyncManager.isUserLoggedIn()

    let playbackTimeHelper = PlaybackTimeHelper()

    @IBOutlet var statsTable: UITableView! {
        didSet {
            statsTable.register(UINib(nibName: "StatsCell", bundle: nil), forCellReuseIdentifier: statsCellId)
            statsTable.register(UINib(nibName: "StatsTopCell", bundle: nil), forCellReuseIdentifier: statsHeaderCellId)
            statsTable.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: Constants.Values.miniPlayerOffset, right: 0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.settingsStats
        Analytics.track(.statsShown)
    }

    private lazy var isInstagramSupported: Bool = {
        guard let storiesUrl = URL(string: "instagram-stories://share") else {
            return false
        }

        return UIApplication.shared.canOpenURL(storiesUrl)
    }()

    private lazy var isFacebookSupported: Bool = {
        guard let storiesUrl = URL(string: "facebook-stories://share") else {
            return false
        }

        return UIApplication.shared.canOpenURL(storiesUrl)
    }()

    @objc func shareTapped() {
        if isInstagramSupported || isFacebookSupported {

            let optionsPicker = OptionsPicker(title: nil)

            if isInstagramSupported {
                let instagramAction = OptionAction(label: "Instagram", icon: nil) { [weak self] in
                    self?.sharePhotoAsStoryInstagram()
                }
                optionsPicker.addAction(action: instagramAction)
            }

            if isFacebookSupported {
                let facebookAction = OptionAction(label: "Facebook", icon: nil) { [weak self] in
                    self?.sharePhotoAsStoryFacebook()
                }
                optionsPicker.addAction(action: facebookAction)
            }

            let shareAction = OptionAction(label: "Share", icon: nil) { [weak self] in
                self?.shareSheet()
            }
            optionsPicker.addAction(action: shareAction)

            optionsPicker.show(statusBarStyle: preferredStatusBarStyle)

        } else {
            shareSheet()
        }
    }

    func sharePhotoAsStoryInstagram() {
      if let storiesUrl = URL(string: "instagram-stories://share") {
        if UIApplication.shared.canOpenURL(storiesUrl) {
          guard let image = statsImage() else { return }
          guard let imageData = image.pngData() else { return }
          let pasteboardItems: [String: Any] = [
          "com.instagram.sharedSticker.backgroundImage": imageData,
          "com.instagram.sharedSticker.backgroundTopColor": "#636e72",
          "com.instagram.sharedSticker.backgroundBottomColor": "#b2bec3"
          ]
         let pasteboardOptions = [
         UIPasteboard.OptionsKey.expirationDate:
         Date().addingTimeInterval(300)
         ]
         UIPasteboard.general.setItems([pasteboardItems], options:
         pasteboardOptions)
         UIApplication.shared.open(storiesUrl, options: [:],
         completionHandler: nil)
         self.dismiss(animated: true, completion: nil)
       } else {
         print("Sorry the application is not installed")
       }
     }
    }

    func sharePhotoAsStoryFacebook() {
        if let storiesUrl = URL(string: "facebook-stories://share") {
          if UIApplication.shared.canOpenURL(storiesUrl) {
            guard let image = statsImage() else { return }
            guard let imageData = image.pngData() else { return }
            let pasteboardItems: [String: Any] = [
            "com.facebook.sharedSticker.backgroundImage": imageData,
            "com.facebook.sharedSticker.backgroundTopColor": "#636e72",
            "com.facebook.sharedSticker.backgroundBottomColor": "#b2bec3",
            "com.facebook.sharedSticker.appID": "328965101026866"
            ]
           let pasteboardOptions = [
           UIPasteboard.OptionsKey.expirationDate:
           Date().addingTimeInterval(300)
           ]
           UIPasteboard.general.setItems([pasteboardItems], options:
           pasteboardOptions)
           UIApplication.shared.open(storiesUrl, options: [:],
           completionHandler: nil)
           self.dismiss(animated: true, completion: nil)
         } else {
           print("Sorry the application is not installed")
         }
       }
    }

    func shareSheet() {
        let finalImage = statsImage()

        let imageToShare = [ finalImage! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]

        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }

    func statsImage() -> UIImage? {
        let tableColor = statsTable.backgroundColor
        statsTable.backgroundColor = nil
        let image = statsTable.sj_snapshotImage()
        statsTable.backgroundColor = tableColor
        let view: UIView = .init(frame: .init(x: 0, y: 0, width: 540, height: 960))
        let imageView = UIImageView(image: image?.trimmingTransparentPixels())
        imageView.backgroundColor = tableColor
        view.addSubview(imageView)
        imageView.center = view.center
        let gradient = CAGradientLayer()

        gradient.frame = view.bounds
        gradient.colors = [AppTheme.colorForStyle(.primaryUi04).cgColor, AppTheme.colorForStyle(.primaryText02).cgColor]

        view.layer.insertSublayer(gradient, at: 0)

        let logo = UIImage(named: AppTheme.pcLogoHorizontalImageName())
        let logoImageView = UIImageView(image: logo)
        view.addSubview(logoImageView)
        logoImageView.center = view.center
        logoImageView.frame = .init(x: logoImageView.frame.origin.x, y: 150, width: logoImageView.frame.width, height: logoImageView.frame.height)

        let finalImage = view.sj_snapshotImage()
        return finalImage
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let shareBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        navigationItem.rightBarButtonItem = shareBtn

        loadStats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Analytics.track(.statsDismissed)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        loadingState == LoadingStatus.loaded ? 3 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 2 {
            return 1
        }

        return 4
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)

        if section == 1 {
            return SettingsTableHeader(frame: headerFrame, title: L10n.statsTimeSaved)
        }

        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 18
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: statsHeaderCellId, for: indexPath) as! StatsTopCell
        }

        return tableView.dequeueReusableCell(withIdentifier: statsCellId, for: indexPath) as! StatsCell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let castCell = cell as! StatsTopCell
            if loadingState == LoadingStatus.failed {
                castCell.loadingIndicator.stopAnimating()
                castCell.descriptionLabel.text = L10n.statsError
                castCell.timeLabel.text = "🤔"
                castCell.accessibilityLabel = L10n.statsError
            } else if loadingState == LoadingStatus.loading {
                castCell.listenLabel.text = L10n.statsListenHistoryLoading
                castCell.timeLabel.text = nil
                castCell.descriptionLabel.text = nil
                castCell.loadingIndicator.startAnimating()
            } else {
                castCell.loadingIndicator.stopAnimating()
                castCell.descriptionLabel.text = FunnyTimeConverter.timeSecsToFunnyText(totalTimeStat())
                castCell.timeLabel.text = formatStat(totalTimeStat())
                if StatsManager.shared.statsStartedAt() > 0 {
                    let startDate = Date(timeIntervalSince1970: TimeInterval(StatsManager.shared.statsStartedAt()))
                    let dateStr = DateFormatter.localizedString(from: startDate, dateStyle: .long, timeStyle: .none)
                    castCell.listenLabel.text = L10n.statsListenHistoryFormat(dateStr)
                } else {
                    castCell.listenLabel.text = L10n.statsListenHistoryNoDate
                }
                castCell.accessibilityLabel = L10n.statsAccessibilityListenHistoryFormat(castCell.timeLabel.text ?? "", castCell.descriptionLabel.text ?? "")
            }
        } else if indexPath.section == 1 {
            let castCell = cell as! StatsCell
            castCell.showIcon()
            if indexPath.row == 0 {
                castCell.statName.text = L10n.statsSkipping
                castCell.statsIcon.image = UIImage(named: "stats_skipping")
                castCell.statValue.text = formatStat(skippedStat())
            } else if indexPath.row == 1 {
                castCell.statName.text = L10n.statsVariableSpeed
                castCell.statsIcon.image = UIImage(named: "stats_speed")
                castCell.statValue.text = formatStat(variableSpeedStat())
            } else if indexPath.row == 2 {
                castCell.statName.text = L10n.settingsTrimSilence
                castCell.statsIcon.image = UIImage(named: "stats_silence")
                castCell.statValue.text = formatStat(silenceRemovedStat())
            } else if indexPath.row == 3 {
                castCell.statName.text = L10n.statsAutoSkip
                castCell.statsIcon.image = UIImage(named: "stats_skip_both")
                castCell.statValue.text = formatStat(autoSkipStat())
            }
            castCell.statValue.style = .primaryText01
        } else {
            let castCell = cell as! StatsCell
            castCell.statName.text = L10n.statsTotal
            castCell.statValue.text = formatStat(skippedStat() + variableSpeedStat() + silenceRemovedStat() + autoSkipStat())
            castCell.statValue.style = .support01
            castCell.hideIcon()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 162
        }

        return 44
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }

    private func loadStats() {
        if localOnly {
            loadingState = LoadingStatus.loaded
            statsTable.reloadData()

            return
        }

        loadingState = LoadingStatus.loading
        StatsManager.shared.loadRemoteStats { success in
            self.loadingState = success ? .loaded : .failed
            DispatchQueue.main.async { [weak self] in
                self?.statsTable.reloadData()
                self?.requestReviewIfPossible()
            }
        }
    }

    private func skippedStat() -> Double {
        StatsManager.shared.totalSkippedTimeInclusive()
    }

    private func variableSpeedStat() -> Double {
        StatsManager.shared.timeSavedVariableSpeedInclusive()
    }

    private func silenceRemovedStat() -> Double {
        StatsManager.shared.timeSavedDynamicSpeedInclusive()
    }

    private func autoSkipStat() -> Double {
        StatsManager.shared.totalAutoSkippedTimeInclusive()
    }

    private func totalTimeStat() -> Double {
        StatsManager.shared.totalListeningTimeInclusive()
    }

    private func formatStat(_ stat: Double) -> String {
        let days = Int(safeDouble: stat / 86400)
        let hours = Int(safeDouble: stat / 3600) - (days * 24)
        let mins = Int(safeDouble: stat / 60) - (hours * 60) - (days * 24 * 60)
        let secs = Int(safeDouble: stat.truncatingRemainder(dividingBy: 60))
        var output = [String]()

        if let daysHours = formatDaysHours(days: days, hours: hours) {
            output.append(daysHours)
        }

        if days > 0, hours > 0 {
            return output.first ?? ""
        }

        let secondsForDisplay = hours < 1 ? secs : 0
        if let minsSeconds = formatMinsSeconds(mins: mins, secs: secondsForDisplay) {
            output.append(minsSeconds)
        }

        if output.count == 0 {
            let components = DateComponents(calendar: Calendar.current, second: secs)
            return DateComponentsFormatter.localizedString(from: components, unitsStyle: .full) ?? L10n.statsTimeZeroSeconds
        }

        return output.joined(separator: " ")
    }

    private func formatDaysHours(days: Int, hours: Int) -> String? {
        guard days > 0 || hours > 0 else { return nil }
        let components = DateComponents(calendar: Calendar.current, day: days, hour: hours)
        return DateComponentsFormatter.localizedString(from: components, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "")
    }

    private func formatMinsSeconds(mins: Int, secs: Int) -> String? {
        guard mins > 0 else { return nil }
        let components = DateComponents(calendar: Calendar.current, minute: mins, second: secs)
        return DateComponentsFormatter.localizedString(from: components, unitsStyle: .short)?.replacingOccurrences(of: ",", with: "")
    }

    private func requestReviewIfPossible() {
        // If the user has listened to more than 2.5 hours the past 7 days
        // And has been using the app for more than a week
        // we kindly request them to review the app
        if playbackTimeHelper.playedUpToSumInLastSevenDays() > 2.5.hours,
           StatsManager.shared.statsStartedAt() > 0,
           let lastWeek = Date().sevenDaysAgo(),
           Date(timeIntervalSince1970: TimeInterval(StatsManager.shared.statsStartedAt())) < lastWeek {
            requestReview(delay: 1)
        }
    }
}

// Image+Trim.swift
//
// Copyright © 2020 Christopher Zielinski.
// https://gist.github.com/chriszielinski/aec9a2f2ba54745dc715dd55f5718177
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

extension UIImage {

    /// Crops the insets of transparency around the image.
    ///
    /// - Parameters:
    ///   - maximumAlphaChannel: The maximum alpha channel value to consider  _transparent_ and thus crop. Any alpha value
    ///         strictly greater than `maximumAlphaChannel` will be considered opaque.
    func trimmingTransparentPixels(maximumAlphaChannel: UInt8 = 0) -> UIImage? {
        guard size.height > 1 && size.width > 1
            else { return self }

        #if canImport(UIKit)
        guard let cgImage = cgImage?.trimmingTransparentPixels(maximumAlphaChannel: maximumAlphaChannel)
            else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        #else
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)?
            .trimmingTransparentPixels(maximumAlphaChannel: maximumAlphaChannel)
            else { return nil }

        let scale = recommendedLayerContentsScale(0)
        let scaledSize = CGSize(width: CGFloat(cgImage.width) / scale,
                                height: CGFloat(cgImage.height) / scale)
        let image = NSImage(cgImage: cgImage, size: scaledSize)
        image.isTemplate = isTemplate
        return image
        #endif
    }

}

extension CGImage {

    /// Crops the insets of transparency around the image.
    ///
    /// - Parameters:
    ///   - maximumAlphaChannel: The maximum alpha channel value to consider  _transparent_ and thus crop. Any alpha value
    ///         strictly greater than `maximumAlphaChannel` will be considered opaque.
    func trimmingTransparentPixels(maximumAlphaChannel: UInt8 = 0) -> CGImage? {
        return _CGImageTransparencyTrimmer(image: self, maximumAlphaChannel: maximumAlphaChannel)?.trim()
    }

}

private struct _CGImageTransparencyTrimmer {

    let image: CGImage
    let maximumAlphaChannel: UInt8
    let cgContext: CGContext
    let zeroByteBlock: UnsafeMutableRawPointer
    let pixelRowRange: Range<Int>
    let pixelColumnRange: Range<Int>

    init?(image: CGImage, maximumAlphaChannel: UInt8) {
        guard let cgContext = CGContext(data: nil,
                                        width: image.width,
                                        height: image.height,
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: CGColorSpaceCreateDeviceGray(),
                                        bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue),
            cgContext.data != nil
            else { return nil }

        cgContext.draw(image,
                       in: CGRect(origin: .zero,
                                  size: CGSize(width: image.width,
                                               height: image.height)))

        guard let zeroByteBlock = calloc(image.width, MemoryLayout<UInt8>.size)
            else { return nil }

        self.image = image
        self.maximumAlphaChannel = maximumAlphaChannel
        self.cgContext = cgContext
        self.zeroByteBlock = zeroByteBlock

        pixelRowRange = 0..<image.height
        pixelColumnRange = 0..<image.width
    }

    func trim() -> CGImage? {
        guard let topInset = firstOpaquePixelRow(in: pixelRowRange),
            let bottomOpaqueRow = firstOpaquePixelRow(in: pixelRowRange.reversed()),
            let leftInset = firstOpaquePixelColumn(in: pixelColumnRange),
            let rightOpaqueColumn = firstOpaquePixelColumn(in: pixelColumnRange.reversed())
            else { return nil }

        let bottomInset = (image.height - 1) - bottomOpaqueRow
        let rightInset = (image.width - 1) - rightOpaqueColumn

        guard !(topInset == 0 && bottomInset == 0 && leftInset == 0 && rightInset == 0)
            else { return image }

        return image.cropping(to: CGRect(origin: CGPoint(x: leftInset, y: topInset),
                                         size: CGSize(width: image.width - (leftInset + rightInset),
                                                      height: image.height - (topInset + bottomInset))))
    }

    @inlinable
    func isPixelOpaque(column: Int, row: Int) -> Bool {
        // Sanity check: It is safe to get the data pointer in iOS 4.0+ and macOS 10.6+ only.
        assert(cgContext.data != nil)
        return cgContext.data!.load(fromByteOffset: (row * cgContext.bytesPerRow) + column, as: UInt8.self)
            > maximumAlphaChannel
    }

    @inlinable
    func isPixelRowTransparent(_ row: Int) -> Bool {
        assert(cgContext.data != nil)
        // `memcmp` will efficiently check if the entire pixel row has zero alpha values
        return memcmp(cgContext.data! + (row * cgContext.bytesPerRow), zeroByteBlock, image.width) == 0
            // When the entire row is NOT zeroed, we proceed to check each pixel's alpha
            // value individually until we locate the first "opaque" pixel (very ~not~ efficient).
            || !pixelColumnRange.contains(where: { isPixelOpaque(column: $0, row: row) })
    }

    @inlinable
    func firstOpaquePixelRow<T: Sequence>(in rowRange: T) -> Int? where T.Element == Int {
        return rowRange.first(where: { !isPixelRowTransparent($0) })
    }

    @inlinable
    func firstOpaquePixelColumn<T: Sequence>(in columnRange: T) -> Int? where T.Element == Int {
        return columnRange.first(where: { column in
            pixelRowRange.contains(where: { isPixelOpaque(column: column, row: $0) })
        })
    }

}
