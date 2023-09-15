import PocketCastsServer

extension SubscriptionTier {
    /// Pocket Casts Plus, or Patron
    var displayName: String {
        switch self {
        case .patron: L10n.patron
        case .plus: L10n.pocketCastsPlus
        case .none: L10n.pocketCastsPlus
        }
    }

    /// Plus, or Patron
    var displayNameShort: String {
        switch self {
        case .patron: L10n.patron
        case .plus: L10n.pocketCastsShort
        case .none: L10n.pocketCastsShort
        }
    }
}
