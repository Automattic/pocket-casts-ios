extension MainTabBarController {
    func presentLoader() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: L10n.hangOn, message: L10n.databaseMigration, preferredStyle: .alert)

            self?.present(alert, animated: true)
            self?.alert = alert
        }
    }

    func dismissLoader() {
        DispatchQueue.main.async { [weak self] in
            self?.alert?.dismiss(animated: true)
        }
    }
}
