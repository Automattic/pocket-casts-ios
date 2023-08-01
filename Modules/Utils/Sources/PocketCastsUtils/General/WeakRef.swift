import Foundation

/// Allows storing a weak reference to an object.
/// This is useful to be able to store an array of weak objects in a store reference.
public final class WeakRef<Obj: AnyObject> {
    weak var object: Obj?

    init(_ object: Obj? = nil) {
        self.object = object
    }
}
