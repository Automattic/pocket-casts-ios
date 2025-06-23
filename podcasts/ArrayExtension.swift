extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    /// Returns the array in grouped in array pairs, if a pair is not available it will return nil
    func pairs() -> [[Element]] {
        var output = [[Element]]()

        for i in stride(from: 0, to: count, by: 2) {
            if i + 1 < count {
                output.append([self[i], self[i+1]])
            } else {
                output.append([self[i]])
            }

        }
        return output
    }

    @discardableResult
    mutating func insert(_ element: Element, safelyAt at: Int) -> Int {
        let indexToInsert = Swift.min(at, count)
        insert(element, at: indexToInsert)
        return indexToInsert
    }
}
