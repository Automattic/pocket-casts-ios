import PocketCastsServer
import UIKit

class CountryCell: ThemeableCell {
    @IBOutlet var countryName: UILabel! {
        didSet {
            countryName.font = .font(ofSize: 16, weight: .medium, scalingWith: .callout)
        }
    }
    @IBOutlet var countryFlag: UIImageView!

    private var region: DiscoverRegion?

    func populateFrom(_ region: DiscoverRegion, selectedRegion: String) {
        self.region = region

        countryName.text = region.name.localized
        countryFlag.kf.setImage(with: URL(string: region.flag))

        accessoryType = (region.code == selectedRegion) ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
    }
}
