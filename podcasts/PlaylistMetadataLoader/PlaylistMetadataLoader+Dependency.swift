import PocketCastsDependencyInjection

struct PlaylistMetadataLoaderKey: DependencyKey {
    static var currentValue = PlaylistMetadataLoader()
}

extension DefaultDependencyContainer {
    var playlistMetadataLoader: PlaylistMetadataLoader {
        get { Self[PlaylistMetadataLoaderKey.self] }
        set { Self[PlaylistMetadataLoaderKey.self] = newValue }
    }
}
