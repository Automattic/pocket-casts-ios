---
area: Up Next
account: plus
tags: regression
---

# Up Next

Up Next as a tab and as a sheet from the player (`podcasts/UpNextViewController.swift`) and Up Next History (`podcasts/Up Next History/`). Fill it with `--fixture up-next:5` first. Up Next syncs to the account, so refill it when a scenario empties it.

## Reorder, remove and clear
tags: smoke, destructive
setup: `--fixture up-next:5`

- Dragging a row by its handle moves it, and the order survives relaunch
- Swiping to remove takes the episode out without playing or archiving it
- Clear asks for confirmation, then shows the empty state
- Settings > Up Next History restores the cleared queue

## Clear from the mini player
tags: destructive
setup: `--fixture up-next:3`

- The mini player's "Close And Clear Up Next" asks for confirmation before clearing, like the Clear button in Up Next
- After clearing, the mini player goes away and the Up Next tab shows its empty state

## Sort and shuffle
setup: `--fixture up-next:5`

- Each sort option orders the queue as named and says which sort is active
- Shuffle works on Plus, and the queue order changes

## Shuffle on a free account
account: free

- Shuffle shows the Plus upsell instead of shuffling

## Multi-select
tags: destructive
setup: `--fixture up-next:5`

- Select several rows, then move to top or bottom, download, mark played or remove. The selection count and the results match
- Leaving multi-select restores normal rows without stale checkmarks

## Up Next from the player
setup: `--fixture up-next:5`

- The player's Up Next sheet and the Up Next tab show the same queue and total time
- Playing the next episode moves the current one out and updates the mini player
- "Play next" and "Play last" on an episode card put the episode where they say

## Empty Up Next
tags: destructive
setup: `--fixture clear-up-next`

- The empty state explains how to add episodes, with no stray total time or Clear button
- Refill it afterwards with `--fixture up-next:5`
