---
area: Deep links
account: plus
tags: regression
---

# Deep links

Routes are in `podcasts/AppDelegate+UrlHandling.swift`. Open them with `xcrun simctl openurl <udid> "<url>"`. The first link after install shows a SpringBoard "Open in Pocket Casts?" alert: tap Open *without* `activationBundleId`. Try links from different tabs, and with a sheet or the full player open.

## Tabs and screens
tags: smoke

- Each of these lands on its tab or screen, even with a sheet or the full player open:
  - `pktc://discover` and `pktc://discover/staff-picks`
  - `pktc://filters`
  - `pktc://upnext?location=tab`
  - `pktc://profile` and `pktc://profile/downloads`
- `pktc://upnext` opens Up Next as a sheet
- `pktc://show_player` opens the player when an episode is loaded, and does nothing harmful when none is

## Content links
- `pktc://social/share/podcast/<podcastUuid>` opens that podcast's page, even for a podcast you don't follow
- `pktc://subscribe/<feed url>` finds the podcast and opens its page without following it. An invalid feed shows a "not found" alert
- `pktc://sharelist/lists.pocketcasts.com/297172b7-948b-4da2-9b0d-7ae9b9068125` shows the shared list
- `https://pocketcasts.com/podcast/<slug>/<uuid>`, with and without a trailing `/`, opens the podcast page. If Safari opens instead, note it but don't log it
- `pktc://widget-episode/<episodeUuid>` opens the episode card for an episode in the library

## Settings and account links
- `pktc://settings/themes`, `pktc://settings/import` and `pktc://settings/storage-and-data` (see settings.md)
- `pktc://upsell` opens the paywall, and a `?source=` parameter is recorded as the source (check the analytics log line)
- `pktc://signup` shows the login screen when signed out, and does something sensible when signed in
- `pktc://redeem/promo/INVALIDCODE` opens the redeem sheet and shows a readable error for the bad code

## Cold start
- Each link above, opened while the app isn't running (`xcrun simctl terminate <udid> au.com.shiftyjelly.podcasts`), lands on its destination and not behind a launch prompt
- An unknown route (`pktc://nope`) does nothing and doesn't crash
