/**
 * VoiceBoostN Internal Header
 *
 * This header exposes the internal state structure for use by the analysis module.
 * DO NOT include this header in external projects - use VoiceBoostN.h instead.
 */

#ifndef VOICEBOOSTN_INTERNAL_H
#define VOICEBOOSTN_INTERNAL_H

#include "VoiceBoostN.h"

#ifdef __cplusplus
extern "C" {
#endif

// Forward declaration for analysis stats (defined in VoiceBoostNAnalysis.h)
typedef struct VBNStats VBNStats;

// Constants
#define VBN_TARGET_LUFS -17.0f  // Pre-compressor target; compressor adds ~3dB → final output ~-14 LUFS
#define VBN_MAX_GAIN_DB 24.0f
#define VBN_MIN_GAIN_DB -12.0f
#define VBN_BLOCK_DURATION 0.4        // 400ms blocks per ITU BS.1770-4
#define VBN_BLOCK_OVERLAP 0.75        // 75% overlap (100ms hop)
#define VBN_MAX_BLOCKS 30             // 3 seconds history for short-term LUFS (10 blocks/sec)
#define VBN_ABSOLUTE_THRESHOLD -70.0f   // ITU BS.1770-4 absolute gate
#define VBN_RELATIVE_THRESHOLD -10.0f   // ITU BS.1770-4 relative gate (LU below ungated)
// Adaptive gain smoothing coefficients (piece-wise linear for CPU efficiency)
#define VBN_GAIN_SMOOTH_FAST   0.70f   // > 10 dB error
#define VBN_GAIN_SMOOTH_MEDIUM 0.80f   // 5-10 dB error
#define VBN_GAIN_SMOOTH_SLOW   0.90f   // 2-5 dB error
#define VBN_GAIN_SMOOTH_STABLE 0.97f   // < 2 dB error (near target)

#define VBN_LIMITER_CEILING 0.794f    // -2.0 dBTP (balanced headroom)
#define VBN_LIMITER_LOOKAHEAD_MS 5.0
#define VBN_LIMITER_RELEASE_MS 100.0
#define VBN_DEQUE_CAPACITY 1024

#define VBN_HP_FREQUENCY 80.0
#define VBN_HP_Q 0.707

#define VBN_COMP_THRESHOLD_DB -8.0f
#define VBN_COMP_RATIO 2.0f
#define VBN_COMP_ATTACK_MS 100.0
#define VBN_COMP_RELEASE_MS 400.0
#define VBN_COMP_KNEE_WIDTH_DB 6.0f    // Soft knee width in dB

// Internal state structure
struct VBNState {
    double sampleRate;

    // LUFS measurement
    float* sampleBuffer;
    int bufferSize;
    int bufferMask;
    int writeIndex;
    int samplesAccumulated;
    int blockSize;
    int hopSize;

    float preFilterDelays[4];
    float rlbFilterDelays[4];
    vDSP_biquad_Setup preFilterSetup;
    vDSP_biquad_Setup rlbFilterSetup;

    float blockLoudnesses[VBN_MAX_BLOCKS];
    int blockCount;
    float currentLUFS;
    float currentGain;
    float targetGain;
    bool hasInitialMeasurement;

    // High-pass filter
    float hpDelays[2][4];
    vDSP_biquad_Setup hpSetup;

    // Compressor
    float compThreshold;
    float compSlope;
    float compAttackCoef;
    float compReleaseCoef;
    float compEnvelopes[2];

    // Limiter
    float limiterGain;
    float limiterReleaseCoef;
    int lookaheadSamples;
    int* dequeIndices;
    float* dequeValues;
    int dequeHead;
    int dequeTail;
    float* peakBuffer;
    float* gainBuffer;
    int maxLimiterBufferSize;

    // Work buffer for LUFS (mono sum)
    float* tempBuffer;
    int tempBufferSize;

    // Analysis mode (only used when analysis module is linked)
    bool analysisEnabled;
    VBNStats* stats;  // Pointer to analysis stats (allocated by analysis module)

    // Temporary storage for before-processing measurements (used by analysis)
    float lastBeforeRMS;
    float lastBeforePeak;
    float lastBeforeTruePeak;
};

#ifdef __cplusplus
}
#endif

#endif // VOICEBOOSTN_INTERNAL_H
