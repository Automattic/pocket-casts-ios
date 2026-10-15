---
area: Player
account: plus
tags: regression
---

# Player

The mini player (`podcasts/MiniPlayerViewController.swift`), the full player and its tabs (`PlayerTabsView.swift`: Now Playing, Show Notes, Chapters, Bookmarks), shelf actions, effects, sleep timer, transcripts and sharing. Audio plays through the Mac: pause as soon as a check is done. Load episodes with `--fixture up-next:3`.

## Mini player and full player
tags: smoke
setup: `--fixture up-next:3`

- Playing an episode shows the mini player with the right title and artwork; tapping it opens the full player, and swiping down closes it
- Play/pause, skip back/forward and scrubbing keep the elapsed and remaining times consistent
- The mini player never hides the last row of a list, and never overlaps the tab bar, with "Minimize tab bar on scroll" on or off
- Long-pressing the mini player shows its menu. "Close And Clear Up Next" asks for confirmation, like Up Next's own Clear button (cancel it)

## Shelf actions
setup: `--fixture up-next:3`

- Every shelf action (effects, sleep timer, star, share, go to podcast, mark played, archive, bookmark, transcript, download, add to playlist) does what its label says, and its icon reflects the new state
- Rearranging the shelf persists after closing the player and after relaunch. Put it back afterwards
- The overflow menu lists the actions that don't fit, each with a label

## Effects
tags: destructive
setup: `--fixture up-next:3`

- Speed changes in 0.1 steps within the allowed range, and the player's effects button shows the speed
- Trim silence and volume boost stay on after closing and reopening the sheet
- Per-podcast effects leave the global effects alone, and clearing them restores the global values
- Set everything back

## Sleep timer
setup: `--fixture up-next:3`

- Each preset starts a countdown shown in the player; +5 minutes adds five minutes; cancel stops it
- "End of episode" and "end of N episodes" show the right labels
- The timer state is still right after closing and reopening the player

## Chapters
- An episode with chapters lists them with times; tapping one jumps there and highlights it
- Skipping (deselecting) chapters works on Plus

## Chapters on a free account
account: free

- Deselecting chapters shows the Plus upsell instead of silently doing nothing

## Transcripts
- "View Transcript" appears only when a transcript can be loaded; opening it never shows a raw error such as an HTTP status
- Search in the transcript highlights matches and steps through them
- Synced scrolling follows playback and stops following when you scroll yourself
- On `free`, generated transcripts show the Plus overlay instead of the text

## Bookmarks
tags: destructive
setup: `--fixture up-next:3`

- Adding a bookmark from the shelf confirms it, and the bookmark shows in the player's Bookmarks tab, the episode card and Profile > Bookmarks
- Editing the title, including picking a suggested title, and deleting both update every list
- Tapping a bookmark plays from its time
- Delete the bookmarks you added

## Share and clips
setup: `--fixture up-next:3`

- Share offers links to the podcast, the episode and the current position, and the system share sheet opens. Cancel it
- The clip editor trims with its handles, and the times and length agree. Don't export or share
