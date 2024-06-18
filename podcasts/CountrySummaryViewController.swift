import PocketCastsServer
import UIKit

class CountrySummaryViewController: UIViewController, DiscoverSummaryProtocol {
    @IBOutlet var selectRegionLabel: ThemeableLabel! {
        didSet {
            selectRegionLabel.text = L10n.discoverSelectRegion
        }
    }

    @IBOutlet var countryFlag: UIImageView!
    @IBOutlet var countryName: ThemeableLabel!
    @IBOutlet var discoverSectionView: ThemeableView! {
        didSet {
            discoverSectionView.style = .primaryUi02
        }
    }

    private weak var delegate: DiscoverDelegate?

    var discoverLayout: DiscoverLayout!

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? ThemeableView)?.style = .primaryUi02

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeCountryTapped))
        discoverSectionView.addGestureRecognizer(tapRecognizer)

        updateRegion(Settings.discoverRegion(discoverLayout: discoverLayout))

        discoverSectionView.layer.borderColor = ThemeColor.primaryUi05().cgColor
        discoverSectionView.layer.borderWidth = 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerDiscoverDelegate(_ delegate: DiscoverDelegate) {
        self.delegate = delegate
    }

    func populateFrom(item: DiscoverItem, region: String?) {}

    @objc private func changeCountryTapped() {
        let countryChooser = CountryChooserViewController()
        let regions = Array(serverRegions().values.map { $0 })
        countryChooser.regions = regions.sorted(by: { region1, region2 -> Bool in
            region1.name.localized.compare(region2.name.localized) == .orderedAscending
        })
        countryChooser.selectedRegion = Settings.discoverRegion(discoverLayout: discoverLayout)
        delegate?.navController()?.pushViewController(countryChooser, animated: true)
    }

    private func updateRegion(_ region: String) {
        guard let serverRegion = serverRegions()[region.lowercased()] else { return }

        countryName.text = serverRegion.name.localized
        countryFlag.kf.setImage(with: URL(string: serverRegion.flag))
        discoverSectionView.accessibilityLabel = L10n.discoverChangeRegion(serverRegion.name)
    }

    func serverRegions() -> [String: DiscoverRegion] {
        discoverLayout.regions!
    }
}
