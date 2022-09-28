import WatchKit

class TopLevelItemRowController: NSObject {
    @IBOutlet var icon: WKInterfaceImage!
    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var episodeCountGroup: WKInterfaceGroup!
    @IBOutlet var episodeCountLabel: WKInterfaceLabel!
    @IBOutlet var topLevelGroup: WKInterfaceGroup!

    func setCount(count: Int) {
        guard count > 0 else {
            episodeCountGroup.setHidden(true)
            return
        }
        let ammendedCount = count > 99 ? "99+" : "\(count)"
        episodeCountLabel.setText(ammendedCount)
        episodeCountLabel.sizeToFitWidth()
        if count > 9 {
            episodeCountGroup.sizeToFitWidth()
        }
    }

    func populate(title: String, count: Int = 0) {
        label.setText(title)
        setCount(count: count)
        if count > 0 {
            topLevelGroup.setAccessibilityLabel("\(title), \(count)")
        } else {
            topLevelGroup.setAccessibilityLabel(title)
        }
    }
}
