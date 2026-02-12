import PocketCastsDependencyInjection

struct PlaylistMetadataLoaderKey: DependencyKey {
    static var currentValue = PlaylistMetadataLoader()
}

struct PlaylistCacheInvalidationCoordinatorKey: DependencyKey {
    static var currentValue = PlaylistCacheInvalidationCoordinator(
        playlistMetadataLoader: PlaylistMetadataLoaderKey.currentValue
    )
}

extension DefaultDependencyContainer {
    var playlistMetadataLoader: PlaylistMetadataLoader {
        get { Self[PlaylistMetadataLoaderKey.self] }
        set { Self[PlaylistMetadataLoaderKey.self] = newValue }
    }

    var playlistCacheInvalidationCoordinator: PlaylistCacheInvalidationCoordinator {
        get { Self[PlaylistCacheInvalidationCoordinatorKey.self] }
        set { Self[PlaylistCacheInvalidationCoordinatorKey.self] = newValue }
    }
}
