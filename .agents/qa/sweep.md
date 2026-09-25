# Visual sweep

`/qa sweep` visits these screens once per setting pass: `dark`, `ax5`, `contrast`, `bold`, `rtl`, `de` and `long-strings` (the commands are in `.agents/skills/qa/reference/checks.md`). Use the `plus` account unless a row says otherwise.

On every screen:

1. Capture it, and scroll long screens once.
2. Compare it with the same screen in the default setting.
3. Check what changes with the setting:
   - clipped or truncated text
   - overlapping views
   - wrong or unreadable colors
   - missing mirroring in RTL, or mirrored icons that shouldn't be
   - untranslated or doubled strings
   - labels missing from the hierarchy

Log one finding per root problem, listing every screen it affects.

| Screen | How to get there |
|---|---|
| Podcasts grid | Podcasts tab |
| Podcasts list layout | Podcasts tab > ··· > List (switch back afterwards) |
| Folder | Podcasts tab > a folder |
| Podcast page | Tap a podcast, or `pktc://social/share/podcast/<uuid>` |
| Podcast settings | Podcast page > gear |
| Episode card | Tap an episode |
| Mini player | Load an episode (`--fixture up-next:3`) |
| Full player: Now Playing, Show Notes, Chapters, Bookmarks | Tap the mini player, then each tab |
| Effects | Player > Effects |
| Sleep timer | Player > Sleep timer |
| Transcript | Player > Transcript, on an episode that has one |
| Up Next | `pktc://upnext?location=tab` |
| Playlists | `pktc://filters` |
| Playlist detail | Playlists > New Releases |
| Discover | `pktc://discover` |
| Category list | Discover > a category pill |
| Search: results and no results | Discover > Search |
| Profile | `pktc://profile` |
| Stats | Profile > Stats |
| Downloads | `pktc://profile/downloads` |
| Listening History | Profile > Listening History |
| Account | Profile > header |
| Settings | Profile > gear |
| Appearance | `pktc://settings/themes` |
| General settings | Settings > General |
| Paywall | `pktc://upsell` (close it without buying) |
| Login landing | `pktc://signup`, on a `signed-out` simulator |
