# Synced Transcript Highlighting — How It Works

A guide for Pocket Casts iOS **synced highlighting**
feature: the transcript line/word that lights up and stays in step with playback
as audio plays. This document is *only* about the sync mechanism — audio
fingerprinting, the playback ↔ transcript time mapping, and the highlight UI that
rides on top of it. It assumes a transcript has already been fetched and parsed
into timed cues elsewhere.

---

## 1. The problem it solves

A transcript's cue timestamps live on the **reference timeline** — the timeline
of the audio the transcript was generated against. The audio actually playing on
the device lives on the **playback timeline**. These two are *not* the same clock:

- **Dynamically-inserted ads** are stitched into the stream per-listener. They
  might or might not be in the transcript at all, and they shift and stretch everything after
  them relative to the reference timeline.
- Different encodings, leading silence, and platform-specific pre-roll add more
  offset.

So we cannot just take `playbackTime` and look up the cue at that timestamp — by
the second ad break we'd be highlighting the wrong sentence (or a sentence during
an ad that has no transcript at all).

**The solution:** listen to the audio coming out of the device, fingerprint it,
and match those fingerprints against a server-provided reference fingerprint of
the original episode. That tells us, moment to moment, *where in the reference
timeline the current audio really is* — which is exactly what we need to pick the
right cue. The output is a **time mapping** between the two timelines that the
highlight UI queries every frame.

```
   device audio  ──► fingerprint windows ──► match vs reference ──► (playback↔reference) mapping
   (may include ads)        (8s @ 1s)            checkpoints              │
                                                                         ▼
                                          highlight UI asks: "given playbackTime,
                                          what reference time am I at — and am I
                                          confidently on matched content?"
```

---

## 2. Gating

| Gate | Where | Meaning |
|------|-------|---------|
| `FeatureFlag.syncedTranscripts` | `Modules/Sources/PocketCastsUtils/Feature Flags/FeatureFlag.swift` | Master switch for the whole sync engine, tap-to-seek, and auto-scroll-back. |
| `PaidFeature.syncedTranscripts = .plusFeature` | `podcasts/PaidFeature.swift` | Synced highlighting is a Plus feature; non-subscribers get the upsell flow, not live highlighting. |
| A **generated** transcript | runtime | Only Pocket Casts-*generated* transcripts have a reference fingerprint published, so sync (and tap-to-seek) only work for them. External transcripts have no reference. |

If the flag is off, no episode, an invalid duration, or no reference is available,
the engine ends in `.unavailable` and the transcript falls back to a plain,
non-highlighting view.

---

## 3. The moving parts

| Component | File | Role |
|-----------|------|------|
| `FingerprintTimingManager` | `podcasts/Fingerprint/FingerprintTimingManager.swift` | The engine. Builds and serves the playback↔reference mapping. Singleton. |
| `FingerprintReferenceRetriever` | `podcasts/Fingerprint/FingerprintReferenceRetriever.swift` | Downloads + gzip-decompresses the reference fingerprint for an episode. `actor`. |
| `ReferenceFingerprint` | `podcasts/Fingerprint/ReferenceFingerprint.swift` | Decodes the reference JSON into checkpoints (timestamp + audio hashes). |
| `FingerprintMappingCache` | `podcasts/Fingerprint/FingerprintMappingCache.swift` | Persists a completed mapping next to the audio file so reopening is instant. |
| `FingerprintConstants` | `podcasts/Fingerprint/FingerprintConstants.swift` | Every tuning constant (window sizes, score thresholds, drift filter, gaps). |
| `FingerprintDebugOverlay` | `podcasts/Fingerprint/FingerprintDebugOverlay.swift` | DEBUG-only visualizer of matches vs. rejections. |
| `Fingerprint` (SwiftPM pkg) | external `pocket-casts-ios-fingerprint` | Rust-backed fingerprinting/matching primitives (see §9). |
| `TranscriptViewController` | `podcasts/TranscriptViewController.swift` | Consumes the mapping: per-frame highlight, auto-scroll, tap-to-seek. |

---

## 4. The reference fingerprint

### 4.1 Where it comes from
For a generated transcript, the server also publishes a compressed reference
fingerprint alongside it:

```
https://shownotes.pocketcasts.com/generated_transcripts/{podcastUuid}/{episodeUuid}-fingerprints.json.gz
```

(`.net` host on staging — built from `ServerConstants.Urls.generatedTranscripts`.)

`FingerprintReferenceRetriever.fetchReferenceData(podcastUuid:episodeUuid:)`:

- Gzip-inflates the payload (it sniffs the `1f 8b` magic bytes and decodes with
  `COMPRESSION_ZLIB`).
- Retries up to **3×** with exponential backoff on transient/5xx errors. A **404
  means "no reference for this episode"** → sync is simply unavailable.
- De-duplicates concurrent requests per `podcast/episode` key.
- The raw decoded bytes are cached on disk by the timing manager next to the audio
  file as **`<audio-path>.ref.fp.json`**, so reopening the episode skips the
  network entirely (`loadReference` / `saveReferenceData`).

### 4.2 What's inside — `ReferenceFingerprint`
The expected format is **`fingerprint-compact-v2`** (any other `format` string is
rejected). Top-level fields:

| Field (JSON) | Meaning |
|--------------|---------|
| `total_duration` | Length of the reference timeline (seconds). Used to gate the mapping cache on full coverage. |
| `checkpoint_interval` | Spacing of checkpoints. |
| `checkpoint_duration` | Seconds of audio each checkpoint's hashes cover. |
| `timestamp_quantum` | Seconds per `delta` unit (timestamps are delta-encoded). |
| `checkpoints` | Array of `[delta, base64-hashes]` pairs. |

`libraryCheckpoints()` decodes these into `(timestampSeconds, [UInt32] hashes)`:

- `delta`s are accumulated, then multiplied by `timestamp_quantum` to get the
  checkpoint's absolute reference time.
- The base64 `data` is the raw little-endian packing of `[UInt32]` hashes. It's
  decoded byte-by-byte (not by reinterpreting the buffer) because `Data` storage
  isn't guaranteed 4-byte aligned and a misaligned `UInt32` load can trap.

These checkpoints are loaded into a `CheckpointMatcher` (§9), one `add(timestamp:
hashes:duration:)` per checkpoint. That matcher is the thing we query each time we
fingerprint a window of device audio.

---

## 5. `FingerprintTimingManager` — the engine

A singleton (`FingerprintTimingManager.shared`) with a small state machine and a
thread-safe serial query queue.

### 5.1 State
```
.idle → .preparing → .active(coverage:)        // happy path
                   ↘ .failed(Error) | .unavailable   // dead ends
```

The transcript UI keys highlighting off this state plus the per-tick "are we on
matched content?" check.

### 5.2 The mapping
The core data structure is two **sorted** arrays of:

```swift
struct TimeMappingEntry {
    let playbackTime: Double   // seconds on the device's playing clock
    let referenceTime: Double  // seconds on the transcript's clock
    let score: Float           // matcher confidence that produced this anchor
}
```

- `playbackToReference` (sorted by `playbackTime`) — "given where the audio is,
  where am I in the transcript?" Drives highlighting.
- `referenceToPlayback` (sorted by `referenceTime`) — the inverse. Drives
  tap-to-seek.

Each committed `TimeMappingEntry` is an **anchor**. Lookups between anchors use
**linear interpolation** (`interpolate(...)`), and **linear extrapolation** at
rate 1 before the first / after the last anchor.

### 5.3 Public query API
All run via `queue.sync` for consistency with the background writer, and are
asserted *not* to be called from the queue itself:

| Method | Used by |
|--------|---------|
| `matchedReferenceTime(forPlaybackTime:)` | The highlight tick. Returns the reference time **only if** we're confidently on matched content (gate + interpolation fused under one lock). |
| `playbackTime(forReferenceTime:)` | Tap-to-seek: tap a cue → seek the player. |
| `isWithinMatchedContent(forPlaybackTime:)` | The highlight confidence gate (see §7). |
| `referenceTime(forPlaybackTime:)` | Ungated mapping (diagnostics/general use). |

### 5.4 Lifecycle entry points
- `prepareForCurrentEpisode()` — kick everything off for the now-playing episode.
- `stop()` — cancel in-flight work, drop the context + mappings, return to
  `.idle`. Called on transcript teardown so we don't keep burning CPU.
- Observes `episodeDownloaded` — if an episode finishes downloading after we'd
  given up (no local file), re-prepare with the complete file.
- Observes `playbackProgress` — drives re-anchoring (§6.4).

---

## 6. Building the mapping (the streaming loop)

### 6.1 Source the audio
`resolveAudioSource(for:)` decides which local file backs the loop:

- **Downloaded** file → `streamFingerprint`: a chunked loop that begins at the
  listener's **current playback position** (not the start of the file) and reads
  forward to EOF. Audio *before* that position is not fingerprinted unless a
  backward seek restarts the pass from there (§6.4). It never waits for bytes —
  the complete file is already on disk.
- **Stream-downloaded** complete file → also a complete file on disk, so it takes
  the same `streamFingerprint` path.
- **Actively streaming** → a still-absent-or-growing buffer
  (`MediaExporterResourceLoaderDelegate`'s temp path, or the legacy streaming
  buffer path) → grow-loop (`streamFingerprintGrowing`) that waits for the file to
  appear and polls for new bytes.

> **We don't fingerprint the whole file.** Coverage spans *current position → EOF*,
> never *0 → EOF*. The forward reach to EOF is real (so tap-to-seek works for any
> cue ahead), but it's throttled, not capped — see §6.7.

### 6.2 Decode → window → match
1. Decode the audio to **Float32 PCM** with `AVAudioFile`, read in
   `streamChunkSeconds` (5 s) chunks.
2. Push interleaved samples into a `StreamingWindowedFingerprinter` configured for
   **8 s windows emitted every 1 s** (`windowDurationMs = 8000`,
   `windowIntervalMs = 1000`).
3. For each emitted `WindowedFingerprint`, ask the `CheckpointMatcher` for the
   **top 2** matches (`findTopMatches(queryHashes:maxResults: 2)`) so we can judge
   how dominant the winner is.
4. The window's absolute playback time is `startOffset + window.timestampMs/1000`;
   the match gives a `referenceTime` (the matched checkpoint's timestamp) and a
   `score`.

Processing starts at the listener's current position (snapped to the window grid
by `alignToWindowGrid`) so highlighting becomes usable for *what's playing now*
without waiting for the whole file to be processed.

### 6.3 Gating a match into an anchor
Before a candidate becomes an anchor it must clear, in order:

1. **Score floor** — `score ≥ matchScoreThreshold` (0.5) just to be considered;
   then `score ≥ driftAnchorScoreThreshold` (0.65) to reach the drift filter.
   (The lower floor is the matcher's confidence minimum; the higher one is "good
   enough to build a mapping on".)
2. **Dominance gate** — top-1 must beat top-2 by `≥ driftScoreDominanceGap`
   (0.05). Correlated false positives from non-matching audio score similarly
   against several nearby reference windows, so a near-tie is a red flag.
3. **Drift filter** — the key anti-noise rule (next).

Rejected candidates are recorded (DEBUG) so the overlay can distinguish "matcher
never fired here" from "matcher fired but we didn't trust it".

### 6.4 The drift filter (`consider(candidate:)`)
> **Invariant:** no anchor — initial bootstrap *or* post-jump — is committed until
> we've seen `driftBootstrapCount` (= 3) consecutive candidates that all project
> from each other at **rate ≈ 1** (Δreference ≈ Δplayback, within
> `driftToleranceSeconds` = 5 s of slack).

- **Fast path:** a candidate in-trend with the last trusted anchor commits
  immediately; any candidates pooled from a not-yet-confirmed jump are flushed as
  rejections (that jump turned out to be noise).
- **Slow path:** candidate goes into a pool. Once the pool's tail is 3 consecutive
  consistent entries, commit them all and drop everything before as noise.
  Otherwise evict the oldest and keep rolling the window.

This is what killed the "highlight jumps around" symptom: a single lucky pair can
never admit an anchor. A jump of *any magnitude* is still allowed — what's
rejected is a point that doesn't sit on a consistent rate-1 line.

### 6.5 Commit, and going `.active`
Accepted entries are inserted in sorted position into both arrays
(`insertMapping`, binary-search insert). Once coverage reaches
`minimumCoverageForActive` (2 entries), state flips to `.active` and
`syncedTranscriptsPreparationCompleted` is tracked once.

### 6.6 Re-anchoring to the listener (`handlePlaybackProgress`)
On each playback-progress tick:
- If playback jumped more than `restartDeltaSeconds` (10 s) — a seek/skip —
  restart the stream from the new position.
- Else if playback drifted outside the mapped range plus
  `playbackRangeMarginSeconds` (30 s) of margin, restart there too.
- A restart keeps existing mappings (still valid) and only resets the drift-filter
  state (the new region has no rate relationship to the old trusted anchor).
- Guard: while no anchors exist yet, don't restart every tick — that would cancel
  the in-flight first-window work before it can finish.

### 6.7 CPU bounding (`throttleIfBeyondLookahead`)
Chunks whose start is more than `lookaheadSeconds` (60 s) ahead of the play-head
are **still processed** (coverage always grows to EOF, so tap-to-seek works
everywhere), but the loop sleeps `outsideLookaheadSleepSeconds` (0.5 s) between
them to cap peak CPU on long episodes. It throttles; it never skips. (An earlier
attempt that *capped* the loop dropped tail regions and broke tap-to-seek for
far-ahead cues.)

### 6.8 Threading
- `queue` — serial queue guarding the mapping arrays and all state.
- `generationQueue` (`.utility`) — the decode/match loop and disk I/O, so JSON
  encoding and audio decode never stall the `queue.sync` query callers (the
  ~60 Hz highlight tick and tap-to-seek).
- A `CancellationFlag` (lock-guarded bool) lets a restart/stop interrupt the
  generation loop within one sleep slice. Late completions for an abandoned
  context are dropped via an `episodeUuid` identity check (`finishIfStillPreparing`).

---

## 7. Why ads don't break it (the two key tricks)

1. **Oversampled windows — 1 s stride vs. the reference's 2 s checkpoint grid.**
   A dynamic ad whose length isn't a multiple of the checkpoint interval
   phase-shifts our windows off that grid. At a 2 s stride, every post-ad window
   would straddle two checkpoints and match neither cleanly — the classic
   "post-mid-roll highlight dies" bug. Emitting every 1 s guarantees that for *any*
   ad offset some window lands within ~0.5 s of a checkpoint; that well-aligned
   window scores dominantly and commits, while the off-phase ones fail the
   dominance gate. No score inflation, no precision loss elsewhere — cost is ~2×
   window hashing.

2. **Opt-in highlighting via the gap gate** (`isWithinMatchedContent` /
   `highlightMaxGapSeconds` = 8 s). We highlight **only while** playback sits
   between two committed anchors no more than 8 s apart. Real content commits
   anchors every second or two, so highlighting tracks continuously, and sparse
   "quick" gaps inside matched audio stay under the bound. A dynamic ad (absent
   from the reference, so no anchors commit across it) opens a wide gap — or leaves
   no committed anchor ahead of the play-head at all — so the instant playback
   crosses the last matched anchor, **highlighting stops**. No ad-detection step to
   lag behind, and we never highlight ad words and then retract them.

> Design principle: **gate on positive confidence** ("only highlight while sure
> we're on matched content") rather than acting by default and undoing once a bad
> state is detected.

---

## 8. The persistent mapping cache

`FingerprintMappingCache` saves a completed mapping next to the audio file as
**`<audio-path>.map.fp.json`**, so reopening a transcript for an
already-fingerprinted **downloaded** episode skips the decode+match pipeline
entirely (`configureForReference` loads it and goes straight to `.active`).

It is deliberately **all-or-nothing**. A cache is loaded only when *all* hold:

- `schemaVersion == mappingCacheSchemaVersion` (bump to invalidate old files),
- reference file identity unchanged (size + mtime) **and** its bytes hash
  (SHA-256) to the same value,
- audio file identity unchanged (size + mtime) **and** a 64 KB content-sample hash
  matches,
- the mapping covers `≥ fullCoverageThreshold` (95 %) of the reference timeline
  (`lastEntry.referenceTime / referenceDuration`).

Anything less and the cache is ignored and a full stream runs. (Partial-cache
short-circuits were what previously trapped the manager in `.preparing`.) Saving
enforces the same 95 % coverage threshold, and only happens for non-streaming
sources after the loop reaches EOF.

---

## 9. The fingerprint primitives (external dependency)

The actual audio fingerprinting and matching live in an external SwiftPM package,
**`pocket-casts-ios-fingerprint`**, exposed as the `Fingerprint` module
(`Modules/Package.swift`). It's a **Rust-built `xcframework`** (`FingerprintFFI`)
wrapped by a UniFFI-generated Swift layer — so the package graph needs the
prebuilt xcframework present to resolve at all.

Key public types used by the timing manager:

```swift
// Holds the reference checkpoints and matches query hashes against them.
class CheckpointMatcher {
    func add(timestamp: Float, hashes: [UInt32], duration: Float)
    func findTopMatches(queryHashes: [UInt32], maxResults: UInt32) -> [MatchResult]
}

struct MatchResult {
    var timestamp: Float   // matched checkpoint time, seconds
    var score: Float       // similarity 0.0…1.0
}

// Streaming windowed fingerprinter: feed PCM, get windows out.
class StreamingWindowedFingerprinter {
    init(sampleRate: UInt32, channels: UInt16, windowDurationMs: UInt32, windowIntervalMs: UInt32)
    func pushSamplesF32(samples: [Float], channels: UInt16) -> [WindowedFingerprint]
    func flush() -> [WindowedFingerprint]
}

struct WindowedFingerprint {
    var timestampMs: UInt32  // ms from the start of what we fed in
    var durationMs: UInt32
    var hashes: [UInt32]
}
```

iOS treats these as opaque: we feed PCM and reference checkpoints in, and get
windows and scored matches out. All the scoring/locality-hashing math is on the
Rust side.

---

## 10. Tying it to the UI (`TranscriptViewController`)

### 10.1 Start / stop
- On appear, when `syncedTranscripts` is enabled and this is the now-playing
  episode: `FingerprintTimingManager.shared.prepareForCurrentEpisode()`.
- On teardown: `FingerprintTimingManager.shared.stop()`.

### 10.2 The highlight tick
A **`CADisplayLink`** drives `updateTranscriptPosition()` at ~60 Hz (paused when
audio is paused, via `updateHighlightDisplayLinkPauseState`). Each tick:

1. **Bail and clear** unless state is `.active` **and**
   `matchedReferenceTime(forPlaybackTime:)` returns a value. Off matched content —
   ads, unmatched audio, not-yet-fingerprinted regions, or before/after the mapped
   range — the highlight is cleared and left cleared.
2. Resolve the cue at that reference time. `currentCue(at:)` keeps a
   `cachedCueIndex` cursor so normal forward playback is **O(1) amortized**; only
   backward seeks fall back to a scan.
3. If the cue changed, restyle the text and (unless the user is scrolling or
   searching) scroll the cue to ~30 % from the top (`highlightVerticalAnchor`).

`clearHighlight` mutates `textStorage` in place rather than reassigning
`attributedText` (which would reset scroll position), and keys off
`hasRenderedHighlight` so a stale highlight can't linger on screen.

### 10.3 Auto-scroll-back
When the user manually scrolls away, auto-scroll is suppressed for
`autoScrollBackDelay` seconds; then the view eases back to the current highlight —
but only if still playing (yanking the view while paused would fight a user
reading elsewhere). Tracked as `syncedTranscriptsAutoScrollResumed`.

### 10.4 Tap-to-seek
Only enabled for generated transcripts (`isDisplayingGeneratedTranscript`), since
only they have a reference mapping. Tapping a word resolves the cue under the
touch, maps `cue.startTime` (a reference time) through
`playbackTime(forReferenceTime:)`, and seeks the player. If the mapping isn't
ready and the episode is streaming, a "download to seek" toast is shown
(`transcriptTapToSeekStreamingUnavailable`). Emits
`syncedTranscriptsSeekUsed` / `syncedTranscriptsSeekFailed`.
