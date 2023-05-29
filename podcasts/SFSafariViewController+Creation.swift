import SafariServices

extension SFSafariViewController {

    /// Creates a SFSafariViewController with consistent config to be used in the app
    convenience init(with url: URL, config: SFSafariViewController.Configuration = .appDefault) {
        self.init(url: url, configuration: config)
        dismissButtonStyle = .close
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
