public struct Queue<T> {
    private var array = [T]()

    public var isEmpty: Bool {
        array.isEmpty
    }

    public var count: Int {
        array.count
    }

    public mutating func enqueue(_ element: T) {
        array.append(element)
    }

    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }

    public mutating func removeAll() {
        array.removeAll()
    }

    public var front: T? {
        array.first
    }
}
