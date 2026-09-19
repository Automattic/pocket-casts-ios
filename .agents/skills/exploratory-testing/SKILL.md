---
name: exploratory-testing
description: Exploratory QA of the Pocket Casts iOS app on an iOS 27 simulator through the Xcode MCP DeviceInteraction tools, logging bugs, UX, visual and accessibility findings with screenshots to a live Artifact plus a coverage map. Use when asked to exploratory-test, QA or smoke-test the app on a simulator, or to run another round into an existing findings artifact.
user-invocable: true
---

# Exploratory Testing

Drive the running app on a simulator, find as many real issues as possible, and keep a live findings page the user can watch fill up.

Needs Xcode 27 with its MCP server (`xcrun mcpbridge`) connected to Claude Code, and a booted iOS 27 simulator with the app installed and signed in. Without the `Artifact` tool, keep the same findings in a Markdown file in the scratchpad.

## Ground rules

The simulator is signed in to the user's real, synced account.

- **Never pay.** No purchases, trials or paywall confirmations. Opening an upsell to read it is fine.
- **Nothing destructive or negative.** No reporting or rating, no unsubscribing from the user's podcasts, no clearing Up Next (including the mini player's "Close And Clear Up Next"), no sign-out, account deletion, OPML or `.pcasts` import, "Replace folders", or data reset.
- **No audio playback.** It plays on the Mac and syncs progress to the account. Skip/scrub only if you undo it.
- **Keep a change log.** Prefer throwaway objects ("QA Temp" folder or playlist) over editing the user's. Write down every state change as you make it and undo it before finishing. If something changes by accident (a stray tap skips playback), undo it and tell the user.
- **Test, don't fix.** Don't edit repo code.

## 1. Set up

1. `xcrun simctl list devices booted`. DeviceInteraction only accepts **iOS 27** runtimes. Confirm the app is installed: `xcrun simctl listapps $U | grep shiftyjelly`.
2. Record baselines to restore at the end:
   ```bash
   U=<udid>
   xcrun simctl ui $U appearance; xcrun simctl ui $U content_size; xcrun simctl ui $U increase_contrast
   xcrun simctl spawn $U defaults read com.apple.Accessibility ReduceMotionEnabled
   xcrun simctl spawn $U defaults read com.apple.Accessibility EnhancedTextLegibilityEnabled
   ```
3. `DeviceInteractionStartSession {deviceIdentifier, sessionIdentifier}`, then one `DeviceInteractionSynthesize` with `activationBundleId: au.com.shiftyjelly.podcasts` to bring the already-running app forward. Sessions die silently after ~20 min ("Session not found") and a name can't be reused, so continue with "… 2", "… 3".
4. Avoid `DeviceInteractionInstallAndRun` (Xcode SIGTERMs it later, which looks like a crash). Relaunch with `xcrun simctl launch $U au.com.shiftyjelly.podcasts`. Any terminate/relaunch ends the user's Xcode debug session; mention it in the report.

## 2. Findings artifact

**New run:** call `Artifact` `quickstart` (intent `other`) first, copy `.agents/skills/exploratory-testing/template.html` to the scratchpad, and publish it with `capabilities: {db: {}, assets: {}}` and icon `bug`. Seed with one `ArtifactData` `batch`:

| Doc | Fields |
|---|---|
| `meta/session` | `build`, `device`, `started`, `status` (shown in the header) |
| `coverage/<slug>` | `area`, `status` (`todo`/`partial`/`done`), `order`, `notes` |
| `findings/fNN` | `n`, `title`, `severity` (`critical`/`major`/`minor`/`note`), `category` (`bug`/`ux`/`a11y`/`visual`/`copy`/`perf`), `area`, `steps[]`, `actual`, `expected`, `notes`, `shots: [{url, caption}]` |

**Another round** ("extend the same file"): list the existing findings, continue numbering after the highest `n`, append coverage areas with higher `order`.

- `update` on an existing doc needs `if_version` (get the doc first), or it fails with `version_mismatch`.
- **Screenshots:** every Synthesize result has a `screenshotPath`. Convert to JPEG into the repo's gitignored `artifacts/qa-shots/` (`sips -s format jpeg -s formatOptions 75 in.png --out artifacts/qa-shots/name.jpg`). Multi-file uploads only accept files under the working directory, so the scratchpad won't do. Upload with `Artifact` `{url, asset: true, file_paths}` and put the returned `url` in the finding's `shots`.
- Log in batches of 2–5 findings as you go, not at the end. The page is the user's live view.

## 3. Driving the simulator

`interactionCommand` grammar; chain with spaces (`;` is rejected), empty command = capture only:

| Command | Action |
|---|---|
| `t x y [hold]` | tap (long-press with a hold) |
| `d x y` | double tap |
| `t x1 y1 f x2 y2 dur` | swipe; `t 210 700 f 210 250 0.3` scrolls down |
| `drag x1 y1 x2 y2 [hold] [move]` | reorder / drag and drop |
| `w sec` | wait |
| `orientation landscapeLeft` | rotate (the iPhone app stays portrait) |
| `sender keyboard kbd <text>` | type; must be last in the chain, `\u{000A}` = Return, `\u{0008}` = backspace. Focus the field in a separate call first |

- **Tap `hitPoint`s from the hierarchy**, never screenshot guesses. The raw file is huge; `.agents/skills/exploratory-testing/scripts/h.sh` (latest dump, or pass `hierarchyPath`) prints labelled elements as `[x,y wxh] @hitX,hitY`. Fall back to screenshot coordinates only for views missing from the hierarchy (player Effects sheet); screenshot pixels are 3× points.
- **Re-read the hierarchy before tapping anything near the tab bar.** The mini player sits right above it, and with "Minimize on Scroll" on, mini-player Skip Forward lands where the Profile tab was.
- Chain `t … w 1 t …` sequences only through screens you've already mapped.
- `applicationState` is always "NotRun"; ignore it.
- Don't paste via `simctl pbcopy`; the Simulator overwrites it with the Mac clipboard.

## 4. What to cover

Write the coverage map before testing, then work through it. Areas that paid off before:

- **Library:** grid/list layouts and badges, folders (create/rename/delete), sort orders, podcast page, per-podcast settings, episode sheet and states (archive, star, played), download start/cancel/delete, multi-select.
- **Player:** mini and full player, effects, sleep timer, bookmarks, chapters, transcripts, share/clip, video episodes, Up Next.
- **Discover and search:** carousel, lists, categories, networks, no-results, recent searches.
- **Playlists, Profile, stats, history, Settings sub-screens, Files, Plus upsell (read only).**
- **Deep links:** `xcrun simctl openurl $U "pktc://settings/themes"`; routes are in `podcasts/AppDelegate+UrlHandling.swift`. The first link shows a SpringBoard "Open in…?" alert; tap it *without* `activationBundleId` (activating SpringBoard sends the app home).
- **Relaunch and state restoration.**

System-setting passes are cheap and find a lot:

| Pass | Turn on | Restore |
|---|---|---|
| Dark mode | `simctl ui $U appearance dark` | baseline |
| Dynamic Type | `simctl ui $U content_size accessibility-extra-extra-extra-large` | baseline |
| Increase Contrast | `simctl ui $U increase_contrast enabled` | `disabled` |
| Reduce Motion, Bold Text | `simctl spawn $U defaults write com.apple.Accessibility ReduceMotionEnabled -bool true` (`EnhancedTextLegibilityEnabled` for Bold), relaunch | write `false`, relaunch |
| RTL | `simctl launch $U au.com.shiftyjelly.podcasts -AppleTextDirection YES -NSForceRightToLeftWritingDirection YES` | plain relaunch |
| Another locale | `… -AppleLanguages "(de)" -AppleLocale de_DE` | plain relaunch |
| Long strings | `… -NSDoubleLocalizedStrings YES` | plain relaunch |
| Signed out, iPad | a second iOS 27 simulator (e.g. an iPad) with the app signed out; never sign out the main one | its orientation |

- **VoiceOver without VoiceOver:** read labels, values and traits in the hierarchy. Red flags: asset names as labels (`discover_add`, `Attachment.png`), clear buttons labelled "Close", icon buttons with no label, no Selected trait on pickers and tabs, content behind a sheet still in the tree, stray punctuation (`EPISODE 357 , TUESDAY`).
- **Contrast:** `python3 .agents/skills/exploratory-testing/scripts/contrast.py shot.png name:x0:y0:x1:y1` (pixel coordinates). Quote the token from `scripts/themes/theme.csv`.
- **After each area, check logs and crashes:**
  ```bash
  xcrun simctl spawn $U log show --last 20m --style compact \
    --predicate 'process == "podcasts" AND (messageType == fault OR messageType == error)'
  ls -t ~/Library/Logs/DiagnosticReports | grep -i podcast | head -3
  xcrun simctl spawn $U launchctl list | grep shiftyjelly   # pid changed = relaunch or crash
  ```

## 5. Before logging a finding

- **Find the code** and cite `path:line` in `notes`; a finding with its cause is worth far more than a symptom.
- **Confirm on screen what the code suggests.** A grep once implied Bold Text was ignored; the simulator showed it wasn't.
- **Check trunk.** The installed build can predate a fix (`git log --oneline -20 -- <file>`, recent PRs). Keep the finding and note the fix.
- **Known non-bugs, don't log:**
  - `1$@ 2$@` under `-NSDoubleLocalizedStrings` (Apple's ByteCountFormatter).
  - The fingerprint debug overlay (`#if DEBUG`).
  - Old `ExcUserFault_podcasts` reports (BoardServices XPC).
  - AirPlay picker not opening, Chromecast (simulator limits).
- **Severity:** critical = crash, data loss or blocked core flow; major = broken feature or wrong result; minor = cosmetic or edge case; note = UX suggestion. Titles state the claim ("Search with no matches shows a blank screen").

## 6. Finish

1. Undo everything in the change log. Re-check the simulator settings against the baselines. Relaunch the app plainly if it last ran with arguments.
2. End the device sessions. Delete `artifacts/qa-shots/`; `git status` must be clean.
3. Mark coverage and set `meta/session` `status` to "Round N complete".
4. Report: artifact link, new and total counts, the top findings by impact, what held up, every state change and how it was restored, and what couldn't be tested.
