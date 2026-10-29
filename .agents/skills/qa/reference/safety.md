# Safety rules

A run uses one of two rule sets, recorded as `rules:` in `run.md`:

- **test** (the default): pool simulators signed in to shared test accounts.
- **real** (`--real`): a simulator signed in to someone's own account.

## Always

- **Never pay.** No purchases, trials, gift or guest-pass sends, or paywall confirmations, on any account. Opening a paywall to read it is fine.
- **Nothing leaves the app.** Don't send feedback or support requests, rate or report podcasts, post, share to another app, or export to a destination. Opening a share sheet or form to check it is fine; cancel it.
- **The account itself stays intact.** Don't change the password or email, and don't delete the account.
- **Only touch your simulators.** Use the UDIDs you were given. Don't boot, erase or change settings on any other simulator.
- **Test, don't fix.** Don't edit the repo. Apart from the run folder, `git status` must be unchanged when you finish.

## Test accounts (`rules: test`)

Other people and other runs use the same accounts, so leave each one as you found it.

- **Destructive actions are allowed:** clearing Up Next, unfollowing, deleting folders or playlists, signing out. Prefer throwaway objects named "QA Temp …". Put things back when the scenario is done: refollow, re-add, or `launch.sh --fixture up-next:5`.
- **Synced settings go back** when the scenario is done: playback, archive, auto-download, appearance, region, notifications. Note each change as you make it.
- **Import only files the scenario provides.** A `.pcasts` import replaces the whole library, and the change syncs to the account.
- **Playback is allowed.** It plays through the Mac's speakers, so pause right after the check.

## Real account (`rules: real`)

The simulator is signed in to someone's own synced account.

- **No destructive or negative actions.** That means no:
  - unfollowing
  - clearing Up Next, including the mini player's "Close And Clear Up Next"
  - signing out
  - OPML or `.pcasts` import
  - "Replace folders"
  - data reset
- **No audio playback.** It syncs progress to the account. Skip or scrub only if you undo it.
- **Keep a change log.** Prefer throwaway objects, write down every change as you make it, and undo everything before finishing. If something changes by accident, undo it and tell the user.
- **Relaunches end debug sessions.** Relaunching the app ends the user's Xcode debug session; mention it in the report.
- **Account fixtures are refused.** `launch.sh` refuses fixtures that change account data on an account it didn't sign in to. That's intended; don't work around it.
