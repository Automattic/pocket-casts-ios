extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    @discardableResult
    mutating func insert(_ element: Element, safelyAt at: Int) -> Int {
        let indexToInsert = at <= count ? at : count
        insert(element, at: indexToInsert)
        return indexToInsert
    }
}
