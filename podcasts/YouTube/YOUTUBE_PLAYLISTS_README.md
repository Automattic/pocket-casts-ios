# YouTube Playlists Feature

This feature allows users to connect their YouTube account and browse/play videos from their YouTube playlists using Pocket Casts' existing YouTube playback.

## Files Created

All files use `YouTubePlaylist` prefix to avoid confusion with the app's existing Playlist feature:

### Core Components
- `YouTubePlaylistAuthManager.swift` - OAuth 2.0 authentication with PKCE
- `YouTubePlaylistAPIClient.swift` - YouTube Data API v3 client
- `YouTubePlaylistModels.swift` - Data models (`YouTubeUserPlaylist`, `YouTubePlaylistVideo`)
- `YouTubePlaylistViewModels.swift` - View models for list and detail views

### UI Components (SwiftUI)
- `YouTubePlaylistConnectView.swift` - OAuth sign-in screen
- `YouTubePlaylistListView.swift` - Playlists browser
- `YouTubePlaylistDetailView.swift` - Playlist videos view
- `YouTubePlaylistsViewController.swift` - UIKit hosting controller

### Integration Points
- `ProfileViewController.swift` - Added "YouTube Playlists" menu item
- `AnalyticsEvent.swift` - Added `youTubePlaylistItemTapped` event
- `podcasts-Bridging-Header.h` - Added CommonCrypto import for PKCE
- `podcasts-Info.plist` - Added OAuth config keys and URL scheme

## Setup Required

### 1. Get Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable **YouTube Data API v3**
4. Create OAuth 2.0 Client ID:
   - Application type: iOS
   - Bundle ID: `au.com.shiftyjelly.podcasts`
5. Copy Client ID and Client Secret

### 2. Update Info.plist

Open `podcasts-Info.plist` and replace:

```xml
<key>YouTubeOAuthClientSecret</key>
<string>GOCSPX-YOUR_CLIENT_SECRET_HERE</string>
```

with your actual client secret from Google Cloud Console.

The Client ID and Redirect URI are already configured.

### 3. Build and Test

```bash
make build
```

Then:
1. Open app → Profile tab
2. Tap "YouTube Playlists"
3. Sign in with Google
4. Browse playlists and play videos!

## Architecture

### Authentication Flow
1. User taps "Sign In with Google"
2. `YouTubePlaylistAuthManager` opens OAuth flow via `ASWebAuthenticationSession`
3. User authenticates in web view
4. OAuth code is exchanged for access/refresh tokens using PKCE
5. Tokens stored securely in Keychain
6. Automatic token refresh when expired

### Data Flow
1. `YouTubePlaylistAPIClient` fetches playlists using access token
2. API responses decoded to `YouTubeUserPlaylist` models
3. View models manage loading states
4. SwiftUI views display data
5. Tapping video hands off to existing YouTube playback via `NavigationManager`

## Key Features

✅ **Secure OAuth 2.0** with PKCE  
✅ **Automatic token refresh**  
✅ **Keychain storage**  
✅ **Pagination** for large playlists  
✅ **Pull to refresh**  
✅ **Theme support** (light/dark)  
✅ **Error handling** with retry  
✅ **Analytics tracking**  

## Naming Convention

All classes/structs use `YouTubePlaylist` prefix to avoid conflicts:

- `YouTubePlaylistAuthManager` (not `PlaylistAuthManager`)
- `YouTubeUserPlaylist` (not `UserPlaylist`)
- `YouTubePlaylistVideo` (not `PlaylistVideo`)
- `YouTubePlaylistListView` (not `PlaylistListView`)
- etc.

This ensures no confusion with the app's existing Playlist feature.

## Testing

Run the app and test:
- [ ] OAuth flow completes successfully
- [ ] Playlists load and display
- [ ] Videos play when tapped
- [ ] Pull to refresh works
- [ ] Sign out/in again works
- [ ] Dark mode displays correctly
- [ ] Error states show properly

## Next Steps

1. Replace placeholder client secret in Info.plist
2. Test OAuth flow thoroughly
3. Verify video playback works with existing YouTube player
4. Add localized strings if needed
5. Consider custom playlist icon (currently using SF Symbol)

## Dependencies

- **iOS 17+**
- **AuthenticationServices** framework
- **CommonCrypto** (for PKCE)
- **PocketCastsUtils** module
- YouTube Data API v3 access

## Support

For issues with:
- **OAuth**: Check Google Cloud Console configuration
- **API errors**: Verify YouTube Data API v3 is enabled
- **Playback**: Verify existing YouTube playback works
- **Build errors**: Check all files are added to target
