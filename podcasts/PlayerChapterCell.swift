import PocketCastsUtils
import UIKit

class PlayerChapterCell: UITableViewCell {
    @IBOutlet var chapterName: UILabel!
    @IBOutlet var chapterLength: UILabel!
    @IBOutlet var chapterNumber: UILabel!
    @IBOutlet var nowPlayingAnimation: NowPlayingAnimationView!
    @IBOutlet var linkAndTimeView: UIView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(linkTapped(_:)))
            linkAndTimeView.addGestureRecognizer(tap)
            linkAndTimeView.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet var linkView: UIView!
    @IBOutlet var seperatorView: UIView!
    @IBOutlet var progressViewWidth: NSLayoutConstraint!
    @IBOutlet var isPlayingView: UIView!
    
    private var onLinkTapped: ((URL) -> Void)?
    private var chapter: ChapterInfo?
    
    enum ChapterPlayState { case played, currentlyPlaying, currentlyPaused, future }
    
    private var playState = ChapterPlayState.played
    
    private var circleCenter: CGPoint!
    var chapterPlayedTime: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(progressUpdated), name: Constants.Notifications.playbackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressUpdated), name: Constants.Notifications.podcastChaptersDidUpdate, object: nil)
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        setSelectedState(selected: selected)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setSelectedState(selected: highlighted)
    }
    
    private func setSelectedState(selected: Bool) {
        switch playState {
        case .currentlyPlaying, .currentlyPaused:
            isPlayingView.backgroundColor = selected ? ThemeColor.playerContrast05() : ThemeColor.playerContrast06()
        case .played, .future:
            backgroundColor = selected ? ThemeColor.playerContrast05() : UIColor.clear
        }
    }
    
    func populateFrom(chapter: ChapterInfo, playState: ChapterPlayState, linkTapped: @escaping ((URL) -> Void)) {
        self.playState = playState
        chapterName.text = chapter.title
        chapterLength.text = TimeFormatter.shared.singleUnitFormattedShortestTime(time: chapter.duration)
        chapterNumber.text = "\(chapter.index + 1)"
        linkView.alpha = playState == .played ? 0.5 : 1
        linkView.isHidden = (chapter.url == nil)
        
        nowPlayingAnimation.animating = false
        chapterName.textColor = playState == .played ? ThemeColor.playerContrast02() : ThemeColor.playerContrast01()
        chapterNumber.textColor = chapterName.textColor
        chapterLength.textColor = chapterName.textColor
        if playState == .currentlyPlaying || playState == .currentlyPaused {
            isPlayingView.isHidden = false
        } else {
            isPlayingView.isHidden = true
            seperatorView.isHidden = true
        }
        
        onLinkTapped = linkTapped
        self.chapter = chapter
        isPlayingView.backgroundColor = ThemeColor.playerContrast06()
        progressUpdated(animated: false)
    }
    
    @IBAction func linkTapped(_ sender: Any) {
        guard let link = chapter?.url, let url = URL(string: link), let linkTapped = onLinkTapped else { return }
        
        linkTapped(url)
    }
    
    @objc func progressUpdated(animated: Bool = true) {
        guard let chapter = chapter, chapter == PlaybackManager.shared.currentChapter() else { return }
        
        layoutIfNeeded()
        
        let lapsedTime = PlaybackManager.shared.currentTime() - chapter.startTime.seconds
        let percentageLapsed = CGFloat(lapsedTime / chapter.duration.seconds)
        
        if percentageLapsed.isFinite, !percentageLapsed.isNaN {
            progressViewWidth.constant = percentageLapsed * isPlayingView.frame.width
        } else {
            progressViewWidth.constant = 0
        }
        
        if animated {
            UIView.animate(withDuration: 0.95) {
                self.layoutIfNeeded()
            }
        } else { layoutIfNeeded() }
    }
}
