/**
 * VoiceBoostN - Podcast Audio Normalizer
 *
 * A high-quality audio normalization library optimized for spoken word content.
 * Implements ITU BS.1770-4 compliant LUFS measurement with adaptive gain control,
 * compression, and true-peak limiting.
 *
 * Target loudness: -14 LUFS (podcast standard)
 *
 * USAGE:
 *   #include "VoiceBoostN.h"
 *
 *   VBNState* vb = VBN_Create(48000.0);
 *   VBN_Process(vb, channels, frameCount, channelCount);
 *   float gain = VBN_GetCurrentGainDB(vb);
 *   VBN_Destroy(vb);
 *
 * REQUIREMENTS:
 *   - Apple Accelerate.framework
 */

#ifndef VOICEBOOSTN_H
#define VOICEBOOSTN_H

#include <Accelerate/Accelerate.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque state handle
typedef struct VBNState VBNState;

// ============================================================================
// Lifecycle
// ============================================================================

/**
 * Create a new VoiceBoostN processor instance.
 *
 * @param sampleRate Audio sample rate in Hz (e.g., 44100, 48000)
 * @return New processor instance, or NULL on allocation failure
 */
VBNState* VBN_Create(double sampleRate);

/**
 * Destroy a processor instance and free all resources.
 *
 * @param state Processor instance (NULL is safely ignored)
 */
void VBN_Destroy(VBNState* state);

/**
 * Reset processor to initial state.
 * Clears all filter states, gain history, and LUFS measurements.
 *
 * @param state Processor instance
 */
void VBN_Reset(VBNState* state);

// ============================================================================
// Processing
// ============================================================================

/**
 * Process audio through the full normalization chain.
 * Audio is processed in-place through:
 *   1. LUFS measurement (ITU BS.1770-4)
 *   2. Adaptive gain (target: -14 LUFS)
 *   3. High-pass filter (80Hz)
 *   4. Compression (-8dB threshold, 2:1 ratio)
 *   5. True-peak limiting (ceiling: -0.13 dBTP)
 *
 * @param state Processor instance
 * @param channels Array of pointers to channel sample buffers (modified in-place)
 * @param frameCount Number of samples per channel
 * @param channelCount Number of channels (1 = mono, 2 = stereo)
 */
void VBN_Process(VBNState* state,
                 float* const* channels,
                 int frameCount,
                 int channelCount);

// ============================================================================
// State Queries (for UI/metering)
// ============================================================================

/**
 * Get the current applied gain in dB.
 *
 * @param state Processor instance
 * @return Current gain in dB (positive = boost, negative = cut)
 */
float VBN_GetCurrentGainDB(const VBNState* state);

/**
 * Get the most recent LUFS measurement of input audio.
 *
 * @param state Processor instance
 * @return Measured loudness in LUFS
 */
float VBN_GetMeasuredLUFS(const VBNState* state);

/**
 * Get the current limiter gain reduction in dB.
 *
 * @param state Processor instance
 * @return Limiter reduction in dB (0 or negative when limiting)
 */
float VBN_GetLimiterReductionDB(const VBNState* state);

/**
 * Get the target loudness.
 *
 * @param state Processor instance
 * @return Target LUFS value (-14.0)
 */
float VBN_GetTargetLUFS(const VBNState* state);

#ifdef __cplusplus
}
#endif

#endif // VOICEBOOSTN_H
