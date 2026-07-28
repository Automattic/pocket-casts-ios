extension Optional {

    struct OptionalNil: Error { }

    func throwOnNil() throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            throw OptionalNil()
        }
    }
}
