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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

            StatsManager.shared.updateLocalStatsIfNeeded { updated in
                if updated {
                    DispatchQueue.main.async { [weak self] in
                        self?.statsTable.reloadData()
                    }
                }
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
        stat.localizedTimeDescription ?? L10n.statsTimeZeroSeconds
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
