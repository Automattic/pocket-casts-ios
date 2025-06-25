extension UserDefaults {
    func track(event: String, id: String) {
        var visits = UserDefaults.standard.dictionary(forKey: event) ?? [:]
        let current = visits[id] as? Int ?? 0
        visits[id] = current + 1
        UserDefaults.standard.set(visits, forKey: event)
    }

    func tracks(for event: String) -> [String: Int]? {
        UserDefaults.standard.dictionary(forKey: event) as? [String: Int]
    }
}
