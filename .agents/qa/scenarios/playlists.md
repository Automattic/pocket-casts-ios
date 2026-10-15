---
area: Playlists
account: plus
tags: regression
---

# Playlists

The Playlists tab (`podcasts/PlaylistsViewController.swift`, `New Creation/`, `New Detail/`). The default smart playlists are New Releases and In Progress. Name everything you create "QA Temp …" and delete it when you're done.

## Default playlists
tags: smoke

- New Releases and In Progress list the episodes their rules describe, and the counts in the Playlists tab match the detail screens
- Play all starts the first episode and queues the rest according to the Up Next settings (pause right away)

## Smart playlist
tags: destructive

- Create "QA Temp Smart" with podcast, status and duration rules. The preview and the saved playlist show the same episodes
- Editing a rule updates the list and the count in the Playlists tab
- Name, icon and auto-download changes persist after relaunch; delete asks for confirmation

## Manual playlist
tags: destructive

- Create "QA Temp Manual", then add episodes from an episode card and from multi-select. They appear in the order added
- Reordering by drag and removing by swipe persist after relaunch
- Adding an episode that's already in the playlist is either prevented or announced, never silently duplicated

## Empty and long playlists
- An empty smart playlist says why it's empty and how to change its rules
- The archived section shows the right count and expands and collapses
- On `heavy`, a long playlist scrolls without blank cells or jumps
