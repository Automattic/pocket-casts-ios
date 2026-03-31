import Foundation

/// A protocol defining a container for managing dependencies.
/// This container allows for the registration and retrieval of dependencies using
/// both a key-based subscript that conforms to `InjectionKey` and a keyPath-based subscript.
public protocol DependencyContainer {

    /// The current instance of the dependency container.
    static var current: Self { get set }

    /**
     Accesses the dependency associated with the provided `InjectionKey`.
     - Parameter key: The `InjectionKey` type to access its associated value.
     - Returns: The value associated with the provided key.
     */
    static subscript<K>(key: K.Type) -> K.Value where K: DependencyKey { get set }

    /**
     Accesses a dependency using a writable key path.
     - Parameter keyPath: The key path to the specific dependency.
     - Returns: The value of the dependency at the specified key path.
     */
    static subscript<T>(_ keyPath: WritableKeyPath<Self, T>) -> T { get set }
}

extension DependencyContainer {
    public static subscript<K>(key: K.Type) -> K.Value where K: DependencyKey {
        get { key.currentValue }
        set { key.currentValue = newValue }
    }

    public static subscript<T>(_ keyPath: WritableKeyPath<Self, T>) -> T {
        get { current[keyPath: keyPath] }
        set { current[keyPath: keyPath] = newValue }
    }
}
