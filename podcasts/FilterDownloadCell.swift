import PocketCastsDataModel
import UIKit

class FilterDownloadCell: ThemeableCell {
    @IBOutlet var filterImage: UIImageView!
    @IBOutlet var filterName: ThemeableLabel!
    @IBOutlet var filterSwitch: ThemeableSwitch!

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    override func setSelected(_ selected: Bool, animated: Bool) {}

    var switchStyle: ThemeStyle = .primaryInteractive01

    var filterSwitchToggled: ((Bool) -> Void)?

    func populateFrom(filter: EpisodeFilter, selected: Bool) {
        filterImage.image = filter.iconImage()
        filterImage.tintColor = filter.playlistColor()
        filterName.text = filter.playlistName
        filterSwitch.isOn = selected

        filterSwitch.addTarget(self, action: #selector(filterSwitchToggled(_:)), for: .valueChanged)
    }

    @objc private func filterSwitchToggled(_ onOffSwitch: UISwitch) {
        filterSwitchToggled?(onOffSwitch.isOn)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        filterSwitch.removeTarget(self, action: #selector(filterSwitchToggled(_:)), for: .valueChanged)
    }

    override func handleThemeDidChange() {
        filterSwitch.onTintColor = AppTheme.colorForStyle(switchStyle)
    }
}
