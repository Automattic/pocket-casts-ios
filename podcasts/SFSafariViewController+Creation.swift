import SafariServices

extension SFSafariViewController {

    /// Creates a SFSafariViewController with consistent config to be used in the app
    static func controller(with url: URL, config: SFSafariViewController.Configuration = .appDefault) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.dismissButtonStyle = .close

        return controller
    }
}

extension SFSafariViewController.Configuration {
    static var appDefault: SFSafariViewController.Configuration {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = false
        return config
    }
}
