---
area: Podcasts
account: plus
tags: regression
---

# Podcasts

The Podcasts tab (`podcasts/Podcasts/All Podcasts/`), the podcast page (`podcasts/Podcasts/Podcast Page/`), podcast settings and folders (`podcasts/Folders/`, Plus only).

## Layouts, sort and badges
tags: smoke

- Large grid, small grid and list each show every followed podcast with artwork. Switch back to the original layout afterwards
- Each sort order (name, release date, date added, drag and drop) orders the items as named, and the choice survives relaunch
- Unplayed badges match the podcast's unplayed episodes (open one podcast to compare)
- Pull to refresh finishes without duplicating or reshuffling items

## Podcast page
tags: smoke

- Opens with the right title, author, artwork and description; a long description expands and collapses
- Episodes, Bookmarks and You Might Like tabs load, and each empty state says what's missing instead of leaving a blank area
- Episode search, sort and grouping change the list as named; clearing the search restores the full list
- "Archive all", "archive played" and "download all" ask before acting on many episodes (cancel them)
- Reloading the feed shows progress and ends with an updated or unchanged list, not an error

## Follow and unfollow
tags: destructive

- Following a podcast from Discover or a shared link updates the button immediately, and the podcast appears in the Podcasts tab
- Unfollowing asks for confirmation, removes the podcast from the tab and any folder, and keeps its downloaded episodes only if the app says so
- Refollow anything you unfollowed

## Podcast settings
tags: destructive

- Each option (auto-download, notifications, auto-add to Up Next and its position, skip first/last, auto-archive, include in playlists) reads back after leaving and reopening. Set them back
- Per-podcast effects apply only to that podcast, and turning them off restores the global effects

## Folders
tags: destructive, plus

- Create "QA Temp" with two podcasts. It appears in the grid with its color and the right podcast count
- Rename it, change the color, add and remove a podcast. Each change shows immediately and survives relaunch
- Deleting the folder keeps its podcasts followed and back in the grid
- `pktc://features/suggestedFolders` (with the Podcasts tab selected) opens Suggested Folders; cancel it

## Folders are Plus-only
account: free

- Creating a folder shows the Plus upsell with a working close button; nothing is created
- Plus-locked items say they're Plus before you tap them, not after

## Library search
- Search in the Podcasts tab finds followed podcasts and folders by partial, case-insensitive name
- No matches shows an explicit empty state, not a blank screen
- Cancel restores the grid at the same scroll position

## Empty library
account: empty

- The Podcasts tab explains how to add podcasts and links to Discover
- Sort, layout and badge options don't offer anything that makes no sense with nothing followed
