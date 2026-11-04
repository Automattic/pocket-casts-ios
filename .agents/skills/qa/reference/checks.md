# What to check

Scripts are in `.agents/skills/qa/scripts/`. `$U` is your simulator's UDID.

## Setting passes

Shards name their setting in `settings:`. Turn it on before the shard and off at the end.

| Setting | On | Off |
|---|---|---|
| `dark` | `sim-settings.sh $U dark` | `sim-settings.sh $U light` |
| `ax5` (largest text) | `sim-settings.sh $U text accessibility-extra-extra-extra-large` | `sim-settings.sh $U text large` |
| `contrast` | `sim-settings.sh $U contrast on` | `sim-settings.sh $U contrast off` |
| `bold` | `sim-settings.sh $U bold on`, then `launch.sh $U` | `sim-settings.sh $U bold off`, then `launch.sh $U` |
| `reduce-motion` | `sim-settings.sh $U motion on`, then `launch.sh $U` | `sim-settings.sh $U motion off`, then `launch.sh $U` |
| `rtl` | `launch.sh $U --rtl` | `launch.sh $U` |
| `de` (or any locale) | `launch.sh $U --locale de_DE` | `launch.sh $U` |
| `long-strings` | `launch.sh $U --double-strings` | `launch.sh $U` |

- **Pool simulators:** turn everything off at once with `sim-settings.sh $U reset`.
- **Real mode:** `sim-settings.sh $U save <file>` first, and `restore <file>` at the end.
- **iPad:** use an iPad simulator: `QA_DEVICE_TYPE="iPad Air 11-inch (M4)" sim-pool.sh up …`.

## Look for

- **Bugs.** Wrong results, actions that silently do nothing, raw errors, crashes, and state that's stale on another screen after a change.
- **Inconsistency.** The same action in two places should behave the same. For example, the mini player cleared Up Next without the confirmation that Up Next's own Clear button asks for.
- **Empty, loading and error states.** Every list needs an empty state. A blank screen is a bug.
- **Layout.**
  - Clipped or truncated text at large sizes
  - Overlapping views
  - Content hidden under the mini player or tab bar
  - Missing or wrong RTL mirroring
  - Landscape on iPad
- **Copy.** Typos, untranslated strings, visible placeholders (`%1$@`), and different names for the same thing.

## Accessibility without VoiceOver

Read labels, values and traits in `h.sh` output. Red flags:
- Asset names as labels (`discover_add`, `Attachment.png`).
- Clear buttons labelled "Close".
- Icon buttons with no label.
- No Selected trait on pickers, tabs and segmented controls.
- Content behind a sheet still in the tree.
- Stray punctuation (`EPISODE 357 , TUESDAY`).

## Contrast

`python3 contrast.py <screenshot.png> name:x0:y0:x1:y1` takes screenshot pixel coordinates (3× points). Normal text needs 4.5:1; large text and icons need 3:1. Name the theme token from the repo's `scripts/themes/theme.csv`, and check whether Increase Contrast changes anything.

## Known non-bugs: don't log

- `1$@ 2$@` under `--double-strings` (Apple's ByteCountFormatter).
- The fingerprint debug overlay, and the Developer and Beta Features rows in Settings (DEBUG builds).
- Old `ExcUserFault_podcasts` reports (BoardServices XPC).
- The AirPlay picker not opening, and Chromecast (simulator limits).
- `https://` universal links opening Safari on a simulator that hasn't linked the domain.
- Staging data quirks (missing artwork, odd Discover content) that don't come from the app.
