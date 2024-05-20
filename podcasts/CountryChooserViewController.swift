import PocketCastsServer
import UIKit

class CountryChooserViewController: PCViewController, UITableViewDataSource, UITableViewDelegate {
    private static let cellId = "CountryCell"

    var regions = [DiscoverRegion]()
    var selectedRegion = ""

    /// Whether the user changed their region or not
    var didChangeRegion = false

    @IBOutlet var countriesTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        countriesTable.register(UINib(nibName: "CountryCell", bundle: nil), forCellReuseIdentifier: CountryChooserViewController.cellId)
        title = L10n.discoverSelectRegion

        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: countriesTable)

        countriesTable.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didChangeRegion {
            Analytics.track(.discoverRegionChanged, properties: ["region": selectedRegion])
        }
    }

    // MARK: - UITableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        regions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CountryChooserViewController.cellId, for: indexPath) as! CountryCell
        let region = regions[indexPath.row]

        cell.populateFrom(region, selectedRegion: selectedRegion)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didChangeRegion = true
        let region = regions[indexPath.row]
        selectedRegion = region.code
        Settings.setDiscoverRegion(region: selectedRegion)
        countriesTable.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        56
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.defaultStatusBarStyle()
    }
}
