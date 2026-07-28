extension UserDefaults {
    enum VisitationTrackEvent: String {
        case discoverCategory

        var key: String {
            "visitation-\(rawValue)"
        }
    }

    func trackVisitation(event: VisitationTrackEvent, id: String) {
        var visits = UserDefaults.standard.dictionary(forKey: event.key) ?? [:]
        let current = visits[id] as? Int ?? 0
        visits[id] = current + 1
        UserDefaults.standard.set(visits, forKey: event.key)
    }

    func visitations(for event: VisitationTrackEvent) -> [String: Int]? {
        UserDefaults.standard.dictionary(forKey: event.key) as? [String: Int]
    }
}
