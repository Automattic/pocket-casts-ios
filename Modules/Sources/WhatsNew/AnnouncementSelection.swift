import PocketCastsUtils

public extension WhatsNew {
    /// Reduces a semver string (e.g. `7.43`, `7.43.0.1`, `7.43.1`) to its
    /// `MAJOR.MINOR` form. Callers feed this into
    /// ``visibleAnnouncement(from:previousOpenedVersion:currentVersion:lastWhatsNewShown:)``
    /// so selection compares only the two leading components.
    static func normalizedVersion(_ version: String) -> String {
        version.majorMinor
    }

    /// Pure selection logic: given a list of announcements and the version
    /// state, return the one that should be presented, or `nil` if none
    /// qualifies.
    ///
    /// - Parameters:
    ///   - announcements: the catalog to pick from, in chronological order.
    ///   - previousOpenedVersion: the last app version the user opened
    ///     before this launch, or `nil` on first run.
    ///   - currentVersion: the app version the user is running now.
    ///   - lastWhatsNewShown: the version whose announcement was last shown
    ///     to the user.
    static func visibleAnnouncement(
        from announcements: [Announcement],
        previousOpenedVersion: String?,
        currentVersion: String,
        lastWhatsNewShown: String?
    ) -> Announcement? {
        // First run, or we've already checked for this version's announcement.
        guard let previousOpenedVersion else { return nil }
        guard lastWhatsNewShown != currentVersion else { return nil }

        // Find the last announcement that:
        // - is enabled
        // - has not been shown already
        // - the target version is not before the last opened version,
        //   and not for a future version
        return announcements.last { announcement in
            announcement.isEnabled() &&
            announcement.version != lastWhatsNewShown &&
            announcement.version.inRange(of: lastWhatsNewShown ?? previousOpenedVersion, upper: currentVersion)
        }
    }
}

extension String {
    /// Given a semver string, ie.: "7.42", "7.43.0.1", "7.43.1"
    /// returns it in the format of MAJOR.MINOR.
    /// Eg.: "7.43", "7.43.0.1" or "7.43.1" will return "7.43".
    var majorMinor: String {
        let splitVersion = split(separator: ".")

        guard let major = splitVersion[safe: 0],
              let minor = splitVersion[safe: 1] else {
            return self
        }

        return "\(major).\(minor)"
    }

    /// Returns whether the version is above the `lower` and equal to or
    /// below the `upper` bounds.
    func inRange(of lower: String, upper: String) -> Bool {
        self >= lower && self <= upper
    }
}
