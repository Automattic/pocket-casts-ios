---
area: Sign-in and upsells
account: signed-out
tags: regression
---

# Sign-in, onboarding and upsells

Onboarding and login (`podcasts/Onboarding/`, `podcasts/Syncing/`) and the paywall. Never buy or start a trial. Opening a paywall to read it is fine. The agent never sees test-account passwords, so sign in with `launch.sh --account`, not by typing.

## First launch
setup: a new simulator (`sim-pool.sh up`), launched with `launch.sh <udid>` and no `quiet` fixture

- The intro carousel pages with swipes and page dots, and "not now" or "skip" leads into the app
- The notification permission sheet, if shown, can be dismissed, and the app works either way

## Log in and sign up forms
tags: smoke

- Wrong credentials (`qa-nobody@example.com`, `wrong-password`) show a readable error and keep the typed email
- Empty and malformed emails are rejected before submitting
- "Forgot password" opens its screen (don't submit it)
- Continue with Apple and Continue with Google open their sheets, and cancelling returns cleanly

## After sign-in
account: plus
setup: `launch.sh <udid> --account plus`

- After the first sync, the account's podcasts, folders, Up Next, playlists, bookmarks and settings are all there
- Profile shows the account and its subscription

## Sign out
tags: destructive
account: plus

- Account > Sign Out asks for confirmation, then Profile shows the signed-out state
- Followed podcasts stay on the device; Plus-only features lock again
- Sign back in with `launch.sh <udid> --account plus` (or move on to the next shard's account)

## Paywall and upsells
- `pktc://upsell` and each Plus-locked feature show a paywall with prices, a monthly/yearly choice and a working close button
- Every Plus-locked feature opens it: folders, bookmarks, Plus themes, shuffle, generated transcripts
- The plans match the account: signed out and free see Plus and Patron. Check `plus` as well, which should only be offered Patron

## Create-account prompt
- Settings > Developer > Tips & Prompts > Trigger Encourage Account Creation Modal, then relaunch: the prompt shows once
- Its buttons lead to sign up or dismiss it, and it doesn't come back on the next launch
