# YouTube Feeds Feature

This feature allows users to add YouTube channels as feeds and browse their videos within Pocket Casts.

## Setup

### YouTube Data API v3

This feature uses the official [YouTube Data API v3](https://developers.google.com/youtube/v3), which requires an API key.

#### Getting an API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Navigate to **APIs & Services** → **Library**
4. Search for and enable **YouTube Data API v3**
5. Go to **APIs & Services** → **Credentials**
6. Click **Create Credentials** → **API Key**
7. Copy the generated key

#### Configuring the API Key

**Option 1: Plist File (Recommended for Development)**

1. Copy `YouTubeAPI.plist.template` to `YouTubeAPI.plist`
2. Replace `YOUR_YOUTUBE_API_KEY_HERE` with your actual API key
3. Add `YouTubeAPI.plist` to your Xcode project
4. **Important**: Add `YouTubeAPI.plist` to `.gitignore` to prevent committing secrets

**Option 2: Environment Variable**

Set the `YOUTUBE_API_KEY` environment variable before launching the app.

**Option 3: Server-Side (Recommended for Production)**

For production apps, it's recommended to:
1. Store the API key on your server
2. Proxy YouTube API requests through your server
3. This prevents API key exposure in the app binary

### API Quotas

The YouTube Data API has usage quotas:
- Default quota: 10,000 units per day
- Each API call costs a certain number of units
- Monitor usage in the [Google Cloud Console](https://console.cloud.google.com/apis/api/youtube.googleapis.com/quotas)

For higher quotas, you can apply for a quota increase through Google.

## Features

- **Add YouTube Channels**: Paste a YouTube URL in the search bar
- **Supported URL formats**:
  - `https://www.youtube.com/channel/UC...` (Channel ID)
  - `https://www.youtube.com/@username` (Handle)
  - `https://www.youtube.com/user/username` (Legacy username)
- **Browse Videos**: View the latest videos from subscribed channels
- **Open in YouTube**: Tap a video to open it in the YouTube app or browser

## Architecture

### Files

- `YouTubeFeed.swift` - Data model for a YouTube channel
- `YouTubeVideo.swift` - Data model for a video
- `YouTubeAPIClient.swift` - Client for YouTube Data API v3
- `YouTubeFeedParser.swift` - High-level API for fetching feeds
- `YouTubeURLDetector.swift` - Utility for parsing YouTube URLs
- `YouTubeFeedManager.swift` - Local storage for saved feeds

### Views

- `YouTubeSearchResultInlineView.swift` - Shown when YouTube URL detected in search
- `YouTubeFeedDetailView.swift` - Detail view for a channel
- `MyYouTubeFeedsView.swift` - List of saved channels (Profile → My YouTube Feeds)
- `YouTubeVideoCell.swift` - Cell displaying a video

## Compliance

This implementation uses the official YouTube Data API v3, which is compliant with YouTube's Terms of Service. Key compliance points:

1. **Official API**: Uses Google's sanctioned API for accessing YouTube data
2. **Attribution**: Opens videos in the YouTube app/browser (proper attribution)
3. **No Scraping**: Does not scrape YouTube web pages
4. **Quota Respect**: Handles quota limits gracefully
5. **User Consent**: User explicitly adds channels they want to follow

## Testing

To test without a real API key, you can mock the `YouTubeAPIClient` responses in unit tests.
