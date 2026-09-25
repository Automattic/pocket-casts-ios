---
area: Settings
account: plus
tags: regression
---

# Settings

Profile > Settings (`podcasts/SettingsViewController.swift`). Settings sync to the account: note every value you change and set it back.

## Every screen opens
tags: smoke

- These screens all open with a title, working back navigation, and no clipped or overlapping rows:
  - General, Notifications, Appearance
  - Auto Archive, Auto Download, Auto Add to Up Next
  - Storage & Data Use, Siri Shortcuts, Headphone Controls, Apple Watch, Files
  - Import, Export, Up Next History, Folders History
  - Privacy, About
- Values shown on the Settings screen itself match the screens behind them

## General
tags: destructive

- Skip forward and back intervals apply to the player's skip buttons and their labels
- The row action and Up Next swipe settings change what tapping or swiping an episode row does
- "Open player automatically" and "Keep screen awake" read back after relaunch

## Appearance
tags: destructive

- Changing the light and dark themes applies immediately everywhere, including the tab bar and mini player
- "Follow system" switches with the simulator (`sim-settings.sh <udid> dark`, then `light`)
- Changing the app icon shows the system confirmation; set it back

## Appearance on a free account
account: free

- Plus themes and app icons are locked and say so, and choosing one opens the Plus upsell

## Auto Archive, Auto Download and Auto Add to Up Next
tags: destructive

- Every option reads back after leaving and reopening the screen
- Podcast pickers list the followed podcasts, with the right ones selected
- Limits and "when full" options show their current value in the row

## Storage & Data Use
- Shows the space used by downloads
- Cleaning up asks for confirmation and says what it will delete (cancel it)

## Notifications
tags: destructive

- Turning on new-episode notifications asks for system permission once, and the podcast picker reflects the selection
- Daily reminders, tips and offers toggle and read back

## Deep links to settings
- `pktc://settings/themes`, `pktc://settings/import` and `pktc://settings/storage-and-data` open the right screen from every tab
- Opening them while Settings > General is already open doesn't stack a second Settings screen underneath
