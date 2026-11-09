# Driving the simulator

Scripts are in `.agents/skills/qa/scripts/`. `$U` is your simulator's UDID.

## Sessions

- `DeviceInteractionStartSession` takes `deviceIdentifier` (always the UDID, never a name) and a `sessionIdentifier`. It returns a session key; pass it as `interactSessionKey` to `DeviceInteractionSynthesize`.
- Your first Synthesize call should use `activationBundleId: au.com.shiftyjelly.podcasts` with an empty command. That brings the app forward and captures the screen.
- Sessions die silently after about 20 minutes ("Session not found"), and a session name can't be reused. Continue with "<name> 2", "<name> 3".
- Call `DeviceInteractionEndSession` when you're done. Open sessions are expensive.
- Launch the app with `launch.sh`. Avoid `DeviceInteractionInstallAndRun` and `DeviceInteractionStartWorkspaceSession`: Xcode SIGTERMs the app later, which looks like a crash.
- `applicationState` is always "NotRun"; ignore it.

## Commands

`interactionCommand` syntax. Chain commands with spaces (`;` is rejected). An empty command only captures the screen.

| Command | Action |
|---|---|
| `t x y [hold]` | Tap, or long-press with a hold time |
| `d x y` | Double tap |
| `t x1 y1 f x2 y2 dur` | Swipe. `t 210 700 f 210 250 0.3` scrolls down |
| `drag x1 y1 x2 y2 [hold] [move]` | Reorder, or drag and drop |
| `w sec` | Wait |
| `orientation landscapeLeft` | Rotate. The iPhone app stays portrait |
| `sender keyboard kbd <text>` | Type. Must be last in the chain. `\u{000A}` is Return, `\u{0008}` is backspace. Focus the field in a separate call first |

## Read the hierarchy, not the pixels

- **Tap `hitPoint`s from the hierarchy**, never guesses from the screenshot.
  - `h.sh "<your session name>"` prints the labelled elements of your newest dump as `[x,y wxh] @hitX,hitY`. You can also pass a `hierarchyPath`.
  - Always pass your session name or path. With no argument it reads the newest dump overall, which can belong to another agent.
- **Screenshot coordinates are a fallback** for views missing from the hierarchy (the player's Effects sheet). Screenshot pixels are 3× points.
- **Re-read the hierarchy before tapping near the tab bar.** The mini player sits right above it. With "Minimize on Scroll" on, the mini player's Skip Forward lands where the Profile tab was.

## Go fast

Every Synthesize call costs about 4 seconds for the capture, on top of your own thinking time, so round trips dominate a run. Separate agents on separate simulators do run in parallel.

- **Jump, don't navigate.**
  - Deep links: `xcrun simctl openurl $U "pktc://…"` (list in `.agents/qa/scenarios/deep-links.md`).
  - Fixtures: `launch.sh $U --fixture up-next:5`.
  - Either one gets you to a state in a single step.
- **Chain known paths.** `t … w 1 t … w 1 t …` in one call, through screens you've already mapped.
- **Read `h.sh` output first.** Open the screenshot only when the hierarchy can't answer: layout, color, clipping.
- **Stay on the scenario.** Note side issues in a line and move on. Log them only when they're clear.

## Launching and state

`launch.sh $U [options]` terminates and relaunches the app. Options:
- `--account <profile>` or `--signed-out`
- `--fixture quiet,no-tips,up-next:5,clear-up-next,subscribe:<uuid>`
- `--rtl`, `--locale de_DE`, `--double-strings`

It prints `[QA]` lines and ends with `[QA] ready` when the hooks are done.

Other ways to change state:
- **Background and foreground:** `xcrun simctl launch $U com.apple.Preferences`, then Synthesize with `activationBundleId`.
- **Push notifications:** `xcrun simctl push $U au.com.shiftyjelly.podcasts payload.json`. `{"aps":{"alert":{"title":"T","body":"B"},"category":"DEEP_LINK"},"destination_url":"pktc://discover"}` opens a deep link.
- **First deep link:** it shows a SpringBoard "Open in…?" alert. Tap it *without* `activationBundleId`; activating SpringBoard sends the app home.
- **Clipboard:** don't paste via `simctl pbcopy`. The Simulator overwrites it with the Mac clipboard.
- **Developer menu:** Settings > Developer (DEBUG builds only).
  - Subscription states: No Plus, Plus, Patron, gift days, expiring and expired. They last until the next sync.
  - Tips, prompts and feature flags (Beta Features).

## Logs and crashes

Check after each scenario:

```bash
xcrun simctl spawn $U log show --last 10m --style compact \
  --predicate 'process == "podcasts" AND (messageType == fault OR messageType == error)' | tail -20
grep -l $U ~/Library/Logs/DiagnosticReports/podcasts-*.ips 2>/dev/null | tail -3   # crashes on your simulator
xcrun simctl spawn $U launchctl list | grep shiftyjelly                            # pid changed = relaunch or crash
```
