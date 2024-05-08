import PocketCastsUtils
import UIKit

class SleepTimerViewController: SimpleNotificationsViewController {
    @IBOutlet var plusFiveBtn: UIButton! {
        didSet {
            plusFiveBtn.setTitle(L10n.sleepTimerAdd5Mins, for: .normal)
            plusFiveBtn.layer.cornerRadius = 12
            plusFiveBtn.layer.borderWidth = 2
            plusFiveBtn.backgroundColor = UIColor.clear
            plusFiveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        }
    }

    @IBOutlet var endOfEpisodeBtn: UIButton! {
        didSet {
            endOfEpisodeBtn.setTitle(L10n.sleepTimerEndOfEpisode, for: .normal)
            endOfEpisodeBtn.layer.cornerRadius = 12
            endOfEpisodeBtn.layer.borderWidth = 2
            endOfEpisodeBtn.backgroundColor = UIColor.clear
            endOfEpisodeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        }
    }

    @IBOutlet var cancelBtn: UIButton! {
        didSet {
            cancelBtn.setTitle(L10n.sleepTimerCancel, for: .normal)
            cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            cancelBtn.layer.cornerRadius = 12
        }
    }

    @IBOutlet var handleView: ThemeableView! {
        didSet {
            handleView.style = .playerContrast02
        }
    }

    @IBOutlet var customTimeStepper: CustomTimeStepper! {
        didSet {
            customTimeStepper.minimumValue = Constants.Limits.minSleepTime
            customTimeStepper.maximumValue = Constants.Limits.maxSleepTime
            customTimeStepper.addTarget(self, action: #selector(customTimeDidChange), for: .valueChanged)
        }
    }

    @IBOutlet var sleepTimerOffView: UIView!
    @IBOutlet var sleepTimerActiveView: UIView!
    @IBOutlet var timeRemaining: ThemeableLabel! {
        didSet {
            timeRemaining.font = timeRemaining.font.monospaced()
            timeRemaining.style = .playerContrast01
        }
    }

    @IBOutlet var sleepTimerOffHeading: UIView!

    @IBOutlet var sleepTimerOffHeadingLabel: ThemeableLabel! {
        didSet {
            sleepTimerOffHeadingLabel.style = .playerContrast02
            sleepTimerOffHeadingLabel.text = L10n.sleepTimer.localizedUppercase
        }
    }

    @IBOutlet var endOfEpisodeLabel: ThemeableLabel! {
        didSet {
            endOfEpisodeLabel.style = .playerContrast01
            endOfEpisodeLabel.text = L10n.sleepTimerEndOfEpisode
        }
    }

    @IBOutlet var activeSleepAnimation: SleepTimerButton!

    @IBOutlet var customTimeBtn: ThemeableUIButton! {
        didSet {
            customTimeBtn.style = .playerContrast01
            customTimeBtn.titleLabel?.font = customTimeBtn.titleLabel?.font.monospaced()
        }
    }

    @IBOutlet var fiveMinutesBtn: ThemeableUIButton! {
        didSet {
            fiveMinutesBtn.style = .playerContrast01
            fiveMinutesBtn.setTitle(TimeFormatter.shared.minutesHoursFormatted(time: 5.minutes), for: .normal)
        }
    }

    @IBOutlet var fifteenMinutesBtn: ThemeableUIButton! {
        didSet {
            fifteenMinutesBtn.style = .playerContrast01
            fifteenMinutesBtn.setTitle(TimeFormatter.shared.minutesHoursFormatted(time: 15.minutes), for: .normal)
        }
    }

    @IBOutlet var thirtyMinutesBtn: ThemeableUIButton! {
        didSet {
            thirtyMinutesBtn.style = .playerContrast01
            thirtyMinutesBtn.setTitle(TimeFormatter.shared.minutesHoursFormatted(time: 30.minutes), for: .normal)
        }
    }

    @IBOutlet var oneHourBtn: ThemeableUIButton! {
        didSet {
            oneHourBtn.style = .playerContrast01
            oneHourBtn.setTitle(TimeFormatter.shared.minutesHoursFormatted(time: 1.hour), for: .normal)
        }
    }

    @IBOutlet var endOfEpisodeInactiveBtn: ThemeableUIButton! {
        didSet {
            endOfEpisodeInactiveBtn.setTitle(L10n.sleepTimerEndOfEpisode, for: .normal)
            endOfEpisodeInactiveBtn.style = .playerContrast01
        }
    }

    @IBOutlet var underFiveDivider: ThemeableView! {
        didSet {
            underFiveDivider.style = .playerContrast05
        }
    }

    @IBOutlet var underFifteenDivider: ThemeableView! {
        didSet {
            underFifteenDivider.style = .playerContrast05
        }
    }

    @IBOutlet var underThirtyDivider: ThemeableView! {
        didSet {
            underThirtyDivider.style = .playerContrast05
        }
    }

    @IBOutlet var underHourDivider: ThemeableView! {
        didSet {
            underHourDivider.style = .playerContrast05
        }
    }

    @IBOutlet var underEndOfEpisodeDivider: ThemeableView! {
        didSet {
            underEndOfEpisodeDivider.style = .playerContrast05
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        updateColors()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissIfNeeded), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addCustomObserver(Constants.Notifications.playbackProgress, selector: #selector(progressUpdated))
        addCustomObserver(Constants.Notifications.themeChanged, selector: #selector(updateColors))

        updateDisplay()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeAllCustomObservers()
    }

    @objc private func progressUpdated() {
        updateSleepRemainingTime()
    }

    @objc private func updateColors() {
        view.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        sleepTimerActiveView.backgroundColor = PlayerColorHelper.playerBackgroundColor01()
        sleepTimerOffView.backgroundColor = PlayerColorHelper.playerBackgroundColor01()

        plusFiveBtn.layer.borderColor = PlayerColorHelper.podcastInteractive03(for: .dark).cgColor
        plusFiveBtn.setTitleColor(PlayerColorHelper.podcastInteractive05(for: .dark), for: .normal)

        endOfEpisodeBtn.layer.borderColor = PlayerColorHelper.podcastInteractive03(for: .dark).cgColor
        endOfEpisodeBtn.setTitleColor(PlayerColorHelper.podcastInteractive05(for: .dark), for: .normal)

        cancelBtn.backgroundColor = PlayerColorHelper.podcastInteractive03(for: .dark)
        cancelBtn.setTitleColor(PlayerColorHelper.podcastInteractive04(for: .dark), for: .normal)

        sleepTimerOffHeading.backgroundColor = PlayerColorHelper.playerBackgroundColor02()
        activeSleepAnimation.tintColor = PlayerColorHelper.playerHighlightColor01(for: .dark)

        customTimeStepper.tintColor = ThemeColor.playerContrast01()
    }

    private func updateSleepRemainingTime() {
        if PlaybackManager.shared.sleepTimeRemaining >= 0, !PlaybackManager.shared.sleepOnEpisodeEnd {
            timeRemaining.isHidden = false
            endOfEpisodeLabel.isHidden = true
            timeRemaining.text = TimeFormatter.shared.playTimeFormat(time: PlaybackManager.shared.sleepTimeRemaining)
            timeRemaining.accessibilityLabel = L10n.sleepTimerTimeRemaining(TimeFormatter.shared.playTimeFormat(time: PlaybackManager.shared.sleepTimeRemaining))
        } else if PlaybackManager.shared.sleepOnEpisodeEnd {
            timeRemaining.isHidden = true
            endOfEpisodeLabel.isHidden = false
        }
    }

    private func updateDisplay() {
        if PlaybackManager.shared.sleepTimerActive() {
            sleepTimerOffView.isHidden = true
            sleepTimerActiveView.isHidden = false
            activeSleepAnimation.sleepTimerOn = true

            let sleepAtEpisodeEnd = PlaybackManager.shared.sleepOnEpisodeEnd
            plusFiveBtn.isHidden = sleepAtEpisodeEnd
            endOfEpisodeBtn.isHidden = sleepAtEpisodeEnd
            updateSleepRemainingTime()
            sleepTimerActiveView.sizeToFit()
        } else {
            sleepTimerOffView.isHidden = false
            sleepTimerActiveView.isHidden = true
            activeSleepAnimation.sleepTimerOn = false

            customTimeStepper.currentValue = Settings.customSleepTime()
            updateCustomSleepTime()
            sleepTimerOffView.sizeToFit()
        }

        let resultSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let newSize = CGSize(width: min(Constants.Values.maxWidthForPopups, view.frame.size.width), height: resultSize.height)
        preferredContentSize = newSize
    }

    private func updateCustomSleepTime() {
        let title = TimeFormatter.shared.minutesHoursFormatted(time: Settings.customSleepTime())
        customTimeBtn.setTitle(title, for: .normal)
    }

    // When the user unlocks the phone and the timer count is active, we check
    // if it's still going on. If not, the view is dismissed.
    @objc private func dismissIfNeeded() {
        if !PlaybackManager.shared.sleepTimerActive(), !sleepTimerActiveView.isHidden {
            dismiss(animated: true)
        }
    }

    // MARK: - Sleep Timer Actions

    @IBAction func fiveMinutesTapped(_ sender: Any) {
        PlaybackManager.shared.setSleepTimerInterval(5.minutes)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func fifteenMinutesTapped(_ sender: Any) {
        PlaybackManager.shared.setSleepTimerInterval(15.minutes)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func thirtyMinutesTapped(_ sender: Any) {
        PlaybackManager.shared.setSleepTimerInterval(30.minutes)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func oneHourTapped(_ sender: Any) {
        PlaybackManager.shared.setSleepTimerInterval(1.hours)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func endOfEpisodeTapped(_ sender: Any) {
        PlaybackManager.shared.sleepOnEpisodeEnd = true
        Analytics.track(.playerSleepTimerEnabled, properties: ["time": "end_of_episode"])
        dismiss(animated: true, completion: nil)
    }

    @IBAction func customTapped(_ sender: Any) {
        PlaybackManager.shared.setSleepTimerInterval(Settings.customSleepTime())
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelTapped(_ sender: Any) {
        Analytics.track(.playerSleepTimerCancelled)
        PlaybackManager.shared.cancelSleepTimer()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func endOfEpisodeActiveTapped(_ sender: Any) {
        PlaybackManager.shared.sleepOnEpisodeEnd = true
        updateDisplay()
        Analytics.track(.playerSleepTimerExtended, properties: ["amount": "end_of_episode"])
    }

    @IBAction func plusFiveTapped(_ sender: Any) {
        PlaybackManager.shared.sleepTimeRemaining += 5.minutes
        updateSleepRemainingTime()
        Analytics.track(.playerSleepTimerExtended, properties: ["amount": Int(5.minutes)])
    }

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func customTimeDidChange() {
        Settings.setCustomSleepTime(customTimeStepper.currentValue)
        updateCustomSleepTime()
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
