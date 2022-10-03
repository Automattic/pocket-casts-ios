import IntentsUI
import PocketCastsDataModel
import UIKit

class PodcastShortcutsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var podcasts: [Podcast]!
    weak var delegate: SiriSettingsViewController?

    let addCellId = "siriAddCellId"
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.siriShortcutToPodcast.localizedCapitalized
        tableView.register(UINib(nibName: "SiriShortcutAddCell", bundle: nil), forCellReuseIdentifier: addCellId)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        podcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: addCellId) as! SiriShortcutAddCell
        let podcast = podcasts[indexPath.row]
        cell.populateFrom(podcast: podcast)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newShortcut = SiriShortcutsManager.shared.playPodcastShortcut(podcast: podcasts[indexPath.row])

        let viewController = INUIAddVoiceShortcutViewController(shortcut: newShortcut)
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = delegate
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
        present(viewController, animated: true, completion: nil)
    }
}
