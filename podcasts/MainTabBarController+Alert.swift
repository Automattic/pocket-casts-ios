extension MainTabBarController {
    func presentLoader() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = ShiftyLoadingAlert(title: L10n.databaseMigration)

            alert.showAlert(self, hasProgress: false, completion: nil)
            self.alert = alert
        }
    }

    func dismissLoader() {
        DispatchQueue.main.async { [weak self] in
            self?.alert?.hideAlert(true)
        }
    }
}
