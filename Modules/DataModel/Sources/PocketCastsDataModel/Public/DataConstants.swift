import Foundation

public enum DataConstants {
    // to support syncing, all user episodes need a podcast UUID, so we have a predefined one all clients use for it
    public static let userEpisodeFakePodcastId = "da7aba5e-f11e-f11e-f11e-da7aba5ef11e"

    // server side, the home folder also needs a UUID, so again we have a predefined value for it all clients use
    public static let homeGridFolderUuid = "973df93c-e4dc-41fb-879e-0c7b532ebb70"
}
