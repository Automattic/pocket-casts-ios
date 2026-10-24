---
area: App lifecycle
account: plus
tags: regression
---

# App lifecycle

Relaunch, background and foreground, long lists, and iPad.

## Relaunch and state restoration
tags: smoke
setup: `--fixture up-next:3`

- After `launch.sh <udid>` relaunches the app, the last tab and the loaded episode (in the mini player, with its position) are restored
- A sheet or the player that was open doesn't come back in a broken state

## Background and foreground
- Switch to another app (`xcrun simctl launch <udid> com.apple.Preferences`) and back: the screen, the scroll position and any typed text are unchanged
- A refresh or download that was running continues or finishes after coming back

## Long lists
account: heavy

- Scrolling the Podcasts grid, a long podcast page, Up Next, a long playlist and Listening History shows no blank cells, no jumps and no duplicated rows
- Opening the player and switching tabs doesn't take noticeably long
- The log has no faults or hang reports while scrolling (`log show … messageType == fault`)

## iPad
setup: an iPad simulator (`QA_DEVICE_TYPE="iPad Air 11-inch (M4)" sim-pool.sh up …`)

- Every tab lays out without stretched, clipped or cramped content, in portrait and landscape (`orientation landscapeLeft`)
- Sheets present as form sheets and dismiss correctly; the player fits the screen
