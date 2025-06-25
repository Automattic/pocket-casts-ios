extension UserDefaults {
    func track(event: String) {
        let visits = UserDefaults.standard.dictionary(forKey: event) ?? [:]
        visits[category.id] += 1
        UserDefaults.standard.jsonObject(visits, forKey: event)
    }
}
