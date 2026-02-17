# Bluetooth Metadata Issue - Technical Exploration Report

## Executive Summary

**Issue:** When users switch from Bluetooth headphones to car Bluetooth while audio is playing or paused, car stereos display "No Title" instead of showing podcast and episode metadata.

**Root Cause:** The `handleRouteChanged` method in `PlaybackManager.swift` does not refresh `MPNowPlayingInfoCenter` metadata when a new audio device becomes available.

**Recommended Fix:** Add `updateAllNowPlayingData()` call when handling `newDeviceAvailable` and `override` route change reasons.

---

## Problem Analysis

### User-Reported Behavior

From ticket [#10358992](https://a8c.zendesk.com/agent/tickets/10358992):

1. User is listening to Pocket Casts through Bluetooth headphones
2. User gets in car; phone connects to car Bluetooth
3. Audio stream switches to car stereo
4. **Expected:** Car screen shows podcast and episode title
5. **Actual:** Car screen shows "No Title" for all metadata fields

### Workarounds That Fix It

Users discovered two workarounds:
1. **Force-close Pocket Casts and reopen** → metadata appears
2. **Play different app's audio (e.g., Apple Music), then return to Pocket Casts** → metadata appears

Both workarounds trigger a full refresh of `MPNowPlayingInfoCenter`.

---

## Technical Investigation

### Current Audio Route Change Handling

**Location:** `podcasts/PlaybackManager.swift:1960-1978`

```swift
@objc private func handleRouteChanged(_ notification: Notification) {
    guard let userInfo = notification.userInfo, 
          let changeReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber else { return }

    logRouteChange(userInfo: userInfo)

    let reason = changeReason.uintValue
    if let currEpisode = currentEpisode(), playingOverAirplay() && playerSwitchRequired() {
        let autoPlay = FeatureFlag.dontAutoplayOnRouteChange.enabled ? false : true
        load(episode: currEpisode, autoPlay: autoPlay, overrideUpNext: false)
    } else if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
        player?.routeDidChange(shouldPause: true)
    } else if reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue || 
              reason == AVAudioSession.RouteChangeReason.override.rawValue {
        player?.routeDidChange(shouldPause: false)  // ⚠️ No metadata update!
    }
}
```

### Route Change Reasons Handled

1. **AirPlay + Player Switch Required** → Calls `load(episode:)` which updates metadata
2. **oldDeviceUnavailable** (headphones unplugged) → Pauses playback
3. **newDeviceAvailable** (new Bluetooth device) → Only calls `routeDidChange(shouldPause: false)` **WITHOUT updating metadata**
4. **override** (route override) → Same as newDeviceAvailable **WITHOUT updating metadata**

### Gap Identified

**The critical gap:** When handling `newDeviceAvailable` or `override`, the code does NOT call any method to refresh `MPNowPlayingInfoCenter`.

---

## MPNowPlayingInfoCenter Update Flow

### When Metadata IS Updated

**Location:** `podcasts/NowPlayingHelper.swift`

Metadata updates occur in these scenarios:

1. **During playback** - Every 1 second via `progressTimerFired` → calls `updateNowPlayingInfo()`
2. **Episode changes** - Via `load(episode:)` → eventually calls `updateAllNowPlayingData()`
3. **Manual notifications** - Various notifications trigger `updateNowPlayingInfo()` or `updateAllNowPlayingData()`
4. **Playback rate changes** - Updates progress and rate info
5. **Chapter changes** - Updates chapter titles if enabled

### When Metadata Is NOT Updated

1. **Route changes to new devices** ❌
2. **While paused** (no timer running) ❌
3. **During route override events** ❌

### NowPlayingHelper Implementation

**Location:** `podcasts/NowPlayingHelper.swift:7-41`

```swift
class func updateNowPlayingInfo(for episode: BaseEpisode, currentChapters: Chapters, 
                                 duration: TimeInterval, upTo: TimeInterval, playbackRate: Double?) {
    guard let currNowPlaying = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
        setAllNowPlayingInfo(for: episode, currentChapters: currentChapters, 
                             duration: duration, upTo: upTo, playbackRate: playbackRate)
        return
    }

    let title = NowPlayingHelper.titleForNowPlayingInfo(episode: episode, currentChapters: currentChapters)
    let nowPlayingTitle = currNowPlaying[MPMediaItemPropertyTitle] as? String
    
    if title == nowPlayingTitle {
        // Just update progress/rate
        let nowPlayingInfo = NowPlayingHelper.addUpToInformationToNowPlaying(
            currNowPlaying as [String: AnyObject], duration: duration, upTo: upTo, playbackRate: playbackRate)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    } else {
        // Full update - title changed
        setAllNowPlayingInfo(for: episode, currentChapters: currentChapters, 
                             duration: duration, upTo: upTo, playbackRate: playbackRate)
    }
}
```

**Key observation:** `updateNowPlayingInfo` optimizes by checking if title matches. If so, it only updates progress. This is efficient but assumes metadata is already set.

---

## Why Route Changes Break Metadata

### Scenario: Headphones → Car Bluetooth (While Playing)

1. User playing podcast through headphones
2. `MPNowPlayingInfoCenter` has correct metadata
3. User gets in car, phone connects to car Bluetooth
4. iOS sends `AVAudioSession.routeChangeNotification` with reason `newDeviceAvailable`
5. Pocket Casts receives notification, calls `handleRouteChanged`
6. Code path: `player?.routeDidChange(shouldPause: false)`
7. **Playback continues, BUT metadata never refreshed**
8. **Some car stereos may clear/reset their metadata display on new connection**
9. Result: Car shows "No Title"

### Scenario: Headphones → Car Bluetooth (While Paused)

Even worse:

1. User pauses podcast while on headphones
2. Update timer stops (no periodic metadata refresh)
3. User gets in car, phone connects to car Bluetooth
4. Route change occurs, but:
   - No metadata update (same issue as above)
   - No timer running to eventually fix it
5. User resumes playback
6. Play resumes, timer starts, but car may have already cached "No Title"

### Why Workarounds Work

**Force-close and reopen:**
- Triggers `PlaybackManager.init()` (line 105)
- Calls `updateAllNowPlayingData()` in init sequence
- Fully resets `MPNowPlayingInfoCenter` with fresh data

**Play other app then return:**
- Other app sets `MPNowPlayingInfoCenter` with its metadata
- When returning to Pocket Casts and pressing play:
  - Title mismatch detected in `updateNowPlayingInfo`
  - Triggers `setAllNowPlayingInfo` (full metadata refresh)

---

## Comparison with AirPlay Handling

**AirPlay route changes ARE handled correctly:**

```swift
if let currEpisode = currentEpisode(), playingOverAirplay() && playerSwitchRequired() {
    let autoPlay = FeatureFlag.dontAutoplayOnRouteChange.enabled ? false : true
    load(episode: currEpisode, autoPlay: autoPlay, overrideUpNext: false)
}
```

The `load(episode:)` call triggers:
1. `setupPlayer()` - Sets up appropriate player
2. Various notifications fire
3. Eventually `updateAllNowPlayingData()` gets called
4. Metadata properly refreshed

**Why not use `load()` for all route changes?**
- Too heavy-handed for simple Bluetooth device switches
- Reinitializes player unnecessarily
- May cause audio glitches
- AirPlay requires it due to player switching (regular AVPlayer vs AirPlay)

---

## Proposed Solution

### Minimal Fix

Add metadata refresh when new devices become available:

```swift
@objc private func handleRouteChanged(_ notification: Notification) {
    guard let userInfo = notification.userInfo, 
          let changeReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber else { return }

    logRouteChange(userInfo: userInfo)

    let reason = changeReason.uintValue
    if let currEpisode = currentEpisode(), playingOverAirplay() && playerSwitchRequired() {
        let autoPlay = FeatureFlag.dontAutoplayOnRouteChange.enabled ? false : true
        load(episode: currEpisode, autoPlay: autoPlay, overrideUpNext: false)
    } else if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
        player?.routeDidChange(shouldPause: true)
    } else if reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue || 
              reason == AVAudioSession.RouteChangeReason.override.rawValue {
        player?.routeDidChange(shouldPause: false)
        // FIX: Refresh metadata when new audio device becomes available
        updateAllNowPlayingData()
    }
}
```

**Impact:**
- **Lines changed:** 1 line added
- **Risk:** Very low - just refreshes existing data
- **Performance:** Negligible - async image loading, only runs on route changes
- **Scope:** Only affects route change handling

### Why `updateAllNowPlayingData()` vs `updateNowPlayingInfo()`

**`updateAllNowPlayingData()`** (used in the fix):
- Forces complete metadata refresh
- Reloads episode artwork
- Ensures all fields are set
- More robust for route changes

**`updateNowPlayingInfo()`** (optimization):
- Checks if title matches first
- Only updates progress if title unchanged
- May not refresh if metadata appears cached

For route changes, we want the **full refresh** to ensure the new device gets all metadata.

---

## Alternative Approaches Considered

### Option A: Always Update on Any Route Change
```swift
@objc private func handleRouteChanged(_ notification: Notification) {
    // ... existing code ...
    
    // Update metadata for all route changes
    updateAllNowPlayingData()
}
```

**Pros:** 
- Most comprehensive
- Handles all edge cases

**Cons:**
- Updates even for internal routing changes
- Slightly excessive
- May update when not needed

### Option B: Update Only for Bluetooth Devices
```swift
else if reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue || 
        reason == AVAudioSession.RouteChangeReason.override.rawValue {
    player?.routeDidChange(shouldPause: false)
    
    // Only update for Bluetooth devices
    if currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP }) {
        updateAllNowPlayingData()
    }
}
```

**Pros:**
- Very targeted to the reported issue
- Minimizes updates

**Cons:**
- More complex logic
- May miss edge cases (CarPlay over USB, etc.)
- Harder to maintain

### Option C: Delayed Update with Debouncing
```swift
else if reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue || 
        reason == AVAudioSession.RouteChangeReason.override.rawValue {
    player?.routeDidChange(shouldPause: false)
    
    // Debounce metadata update to handle rapid route changes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.updateAllNowPlayingData()
    }
}
```

**Pros:**
- Handles rapid route changes gracefully
- Avoids redundant updates

**Cons:**
- Adds delay complexity
- May not be necessary
- Harder to test

---

## Recommendation

**Use the Minimal Fix (proposed solution above):**

1. ✅ **Surgical change** - 1 line added
2. ✅ **Low risk** - only refreshes existing metadata
3. ✅ **Addresses root cause** - ensures metadata updated on route change
4. ✅ **Consistent with existing patterns** - `updateAllNowPlayingData()` is used elsewhere
5. ✅ **Handles both scenarios** - playing and paused states
6. ✅ **No feature flags needed** - straightforward fix

---

## Testing Recommendations

### Manual Testing Scenarios

1. **Primary scenario (reported issue):**
   - Start playing podcast with Bluetooth headphones
   - Get in car, connect to car Bluetooth
   - Verify metadata appears on car screen

2. **Paused state:**
   - Pause podcast while on headphones
   - Connect to car Bluetooth
   - Resume playback
   - Verify metadata appears on car screen

3. **Multiple switches:**
   - Headphones → Car → Headphones → Car
   - Verify metadata updates each time

4. **Different device types:**
   - Bluetooth headphones → Wired headphones → Bluetooth headphones
   - Bluetooth → CarPlay (wireless) → Bluetooth
   - Verify no regressions

5. **AirPlay (regression test):**
   - Ensure AirPlay still works correctly
   - Verify player switching still occurs
   - Check metadata on AirPlay devices

6. **Google Cast (regression test):**
   - Ensure Google Cast still works
   - Verify no interference with cast metadata

### Automated Testing

Consider adding unit tests for:
- `handleRouteChanged` with different route change reasons
- Verify `updateAllNowPlayingData()` is called for `newDeviceAvailable`
- Verify `updateAllNowPlayingData()` is called for `override`
- Verify existing AirPlay behavior unchanged

---

## Related Issues

### Similar CarPlay Issue (Ticket #10822365)

A user reported that CarPlay's **native media player view** doesn't sync properly with Pocket Casts metadata, though CarPlay's own "Now Playing" screen works correctly.

**Observations:**
- Sometimes shows previous episode
- Podcast artwork and episode title don't match
- CarPlay interface itself displays correctly
- Other apps (Spotify) don't have this issue

**Analysis:**
This may be the same root cause. CarPlay has two metadata displays:
1. **CarPlay Now Playing screen** - Uses `MPNowPlayingInfoCenter` directly
2. **Vehicle's native media view** - May cache metadata and not refresh

The fix should help both scenarios by ensuring metadata is always fresh on route changes.

---

## Additional Context

### AVAudioSession Route Change Reasons

For reference, iOS provides these route change reasons:

- `unknown` - Reason is unknown
- `newDeviceAvailable` - A new device became available (e.g., headphones plugged in)
- `oldDeviceUnavailable` - The old device became unavailable (e.g., headphones unplugged)
- `categoryChange` - The audio session category changed
- `override` - The app overrode the output route
- `wakeFromSleep` - The device woke from sleep
- `noSuitableRouteForCategory` - No suitable route for current category
- `routeConfigurationChange` - Route configuration changed

**We're specifically addressing `newDeviceAvailable` and `override`** which cover:
- Bluetooth device connection
- CarPlay connection (USB or wireless)
- Wired headphone connection
- Manual route override by user or app

---

## Files Analyzed

1. **`podcasts/PlaybackManager.swift`** - Main playback orchestration
   - `handleRouteChanged(:)` - Route change handler (line 1960)
   - `updateNowPlayingInfo()` - Updates progress/rate (line 2101)
   - `updateAllNowPlayingData()` - Full metadata refresh (line 2128)

2. **`podcasts/NowPlayingHelper.swift`** - MPNowPlayingInfoCenter wrapper
   - `updateNowPlayingInfo(for:currentChapters:duration:upTo:playbackRate:)` - Smart update (line 7)
   - `setAllNowPlayingInfo(for:currentChapters:duration:upTo:playbackRate:)` - Full update (line 26)
   - `nowPlayingInfo(for:currentChapters:)` - Builds metadata dictionary (line 60)

3. **`podcasts/PlaybackProtocol.swift`** - Player interface
   - `routeDidChange(shouldPause:)` - Protocol method (line 32)

4. **`podcasts/DefaultPlayer.swift`** - Default AVPlayer implementation
   - `routeDidChange(shouldPause:)` - Implementation (pauses if needed)

---

## Conclusion

The Bluetooth metadata issue is caused by a **missing metadata refresh** when new audio devices become available. The fix is straightforward: add one line to call `updateAllNowPlayingData()` in the route change handler for `newDeviceAvailable` and `override` reasons.

This minimal change ensures that whenever a user connects to a new audio device (car Bluetooth, headphones, etc.), the MPNowPlayingInfoCenter is refreshed with current episode metadata, resolving the "No Title" issue reported by users.

---

## Next Steps

If approved to implement:

1. Create feature branch: `fix/PCIOS-240-bluetooth-metadata`
2. Apply the minimal fix to `PlaybackManager.swift`
3. Test all scenarios listed above
4. Run existing test suite for regressions
5. Submit PR with:
   - Clear description of issue and fix
   - Reference to Linear issue PCIOS-240
   - Before/after testing results
   - Screenshots/videos if possible

---

**Report prepared by:** GitHub Copilot Agent  
**Date:** 2026-02-17  
**Linear Issue:** [PCIOS-240](https://linear.app/a8c/issue/PCIOS-240/not-sending-episode-metadata-to-bluetooth-device)  
**Zendesk Tickets:** [#10358992](https://a8c.zendesk.com/agent/tickets/10358992), [#10822365](https://a8c.zendesk.com/agent/tickets/10822365)
