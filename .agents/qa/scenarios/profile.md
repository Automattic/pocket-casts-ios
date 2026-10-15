---
area: Profile
account: plus
tags: regression
---

# Profile and account

The Profile tab (`podcasts/ProfileViewController.swift`, `podcasts/Profile - SwiftUI/`) and the Account screen (`podcasts/AccountViewController*.swift`). Look, but don't change the account: no avatar, email, password or subscription changes.

## Header and stats
tags: smoke

- The header shows the account's email and avatar, and a badge that matches the subscription (Plus, Patron or none)
- Stats show listening time and the heatmap, with numbers formatted for the locale
- Refresh finishes and updates the "last refreshed" time

## Lists
- Downloads, Files, Starred, Bookmarks and Listening History each open and show the account's items
- On `empty`, each shows a meaningful empty state
- Listening History search finds episodes by title
- Clearing Listening History asks for confirmation (cancel it)
- Files shows uploaded files and the storage used

## Account screen
- Shows the subscription type, the renewal or expiry date, and the right upgrade option (Plus offers Patron)
- Cancel subscription, sign out and delete account are there, but stop at their first confirmation and cancel
- Privacy policy and terms open

## Help and feedback
- Help, the status page, Troubleshooting and the logs screen open
- Don't send feedback or export the database

## Subscription states
- Settings > Developer > Subscription switches between No Plus, Plus, Patron, gift days, expiring and expired
- For each state, these all agree with it:
  - Profile's badge
  - the Account screen
  - Plus-only features: folders, bookmarks, Plus themes and icons
  - upsells
- The states last until the next sync. Refresh Profile at the end to go back

## Patron
account: patron

- The Patron badge and Patron app icons show; Patron-only icons can be selected
- The Account screen doesn't offer an upgrade

## Signed out
account: signed-out

- Profile offers sign in or sign up, and the informational banner explains what an account gives you
- Stats, Downloads, Files and History still work locally, or explain that they need an account
