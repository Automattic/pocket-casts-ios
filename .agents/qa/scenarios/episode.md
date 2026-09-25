---
area: Episode
account: plus
tags: regression
---

# Episodes and downloads

The episode card (`podcasts/Episode/EpisodeDetailViewController.swift`), episode rows and swipe actions (`podcasts/Episode Cells/`), downloads (`podcasts/DownloadManager.swift`).

## Episode card
tags: smoke

- Opening an episode from a podcast page, a playlist, Up Next and search shows the same card
- Title, date, duration, artwork and show notes are right; links in show notes open in the app or the browser as Settings > General says
- Play, download, Up Next (play next and play last), star, share, mark played and archive each change state visibly, and the podcast page agrees afterwards
- A transcript excerpt appears only when the episode has a transcript

## Swipe actions and multi-select
tags: destructive

- Swipe actions on episode rows do what their icons say, and match the row action set in Settings > General
- Multi-select: pick several episodes, then download, archive, mark played or add to Up Next. The selection count and the results match, and "select all above/below" selects the right rows
- Leaving multi-select restores normal rows without stale checkmarks
- In the hierarchy, rows expose the swipe actions as accessibility custom actions
- Undo what you changed

## Downloads
tags: destructive

- Starting, cancelling and deleting a download show progress and the result in the row, the episode card and Profile > Downloads
- Downloaded episodes show the downloaded indicator everywhere they're listed
- Deleting a download keeps the episode and its played state

## Played, starred and archived
tags: destructive

- Mark as played and unplayed update the row, the podcast's unplayed badge and the New Releases playlist
- Starred episodes appear in Profile > Starred, and unstarring removes them
- Archived episodes are hidden or shown according to the podcast's "show archived" option
- Undo what you changed
