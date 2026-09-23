/**
 * VoiceBoostN Core Implementation
 *
 * This file contains the core audio processing algorithms:
 * - ITU BS.1770-4 LUFS measurement
 * - Adaptive gain control
 * - High-pass filter
 * - Dynamic range compression
 * - True-peak limiting
 */

#include "VoiceBoostN_Internal.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

// Forward declarations for internal functions
static void calculateLUFSFilterCoefficients(VBNState* state);
static void calculateHighPassCoefficients(VBNState* state);
static void processLUFS(VBNState* restrict state, float* const* restrict channels, int frameCount, int channelCount);
static void applyHighPass(VBNState* restrict state, float* restrict samples, int frameCount, int channel);
static void applyCompression(VBNState* restrict state, float* restrict samples, int frameCount, int channel);
static void applyLimiter(VBNState* restrict state, float* const* restrict channels, int frameCount, int channelCount);
static void measureBlock(VBNState* state);

// ============================================================================
// Deque Operations (for sliding maximum in limiter)
// ============================================================================

static inline bool dequeIsEmpty(const VBNState* state) {
    return state->dequeHead == state->dequeTail;
}

static inline void dequeClear(VBNState* state) {
    state->dequeHead = 0;
    state->dequeTail = 0;
}

static inline void dequePushBack(VBNState* state, int idx, float val) {
    state->dequeIndices[state->dequeTail] = idx;
    state->dequeValues[state->dequeTail] = val;
    state->dequeTail = (state->dequeTail + 1) & (VBN_DEQUE_CAPACITY - 1);
}

static inline void dequePopBack(VBNState* state) {
    state->dequeTail = (state->dequeTail - 1 + VBN_DEQUE_CAPACITY) & (VBN_DEQUE_CAPACITY - 1);
}

static inline void dequePopFront(VBNState* state) {
    state->dequeHead = (state->dequeHead + 1) & (VBN_DEQUE_CAPACITY - 1);
}

static inline int dequeFrontIdx(const VBNState* state) {
    return state->dequeIndices[state->dequeHead];
}

static inline float dequeFrontVal(const VBNState* state) {
    return state->dequeValues[state->dequeHead];
}

static inline float dequeBackVal(const VBNState* state) {
    int back = (state->dequeTail - 1 + VBN_DEQUE_CAPACITY) & (VBN_DEQUE_CAPACITY - 1);
    return state->dequeValues[back];
}

// ============================================================================
// Lifecycle
// ============================================================================

VBNState* VBN_Create(double sampleRate) {
    VBNState* state = (VBNState*)calloc(1, sizeof(VBNState));
    if (!state) return NULL;

    state->sampleRate = sampleRate;

    // LUFS setup
    state->blockSize = (int)(sampleRate * VBN_BLOCK_DURATION);
    state->hopSize = (int)(sampleRate * VBN_BLOCK_DURATION * (1.0 - VBN_BLOCK_OVERLAP));

    // Power-of-2 buffer for fast modulo
    int minSize = state->blockSize * 2;
    state->bufferSize = 1;
    while (state->bufferSize < minSize) state->bufferSize <<= 1;
    state->bufferMask = state->bufferSize - 1;

    state->sampleBuffer = (float*)calloc(state->bufferSize, sizeof(float));
    state->currentLUFS = -24.0f;
    state->currentGain = 1.0f;
    state->targetGain = 1.0f;

    // Calculate filter coefficients and create vDSP setups
    calculateLUFSFilterCoefficients(state);
    calculateHighPassCoefficients(state);

    // Compressor setup
    state->compThreshold = powf(10.0f, VBN_COMP_THRESHOLD_DB / 20.0f);
    state->compSlope = 1.0f - 1.0f / VBN_COMP_RATIO;
    double attackSamples = sampleRate * VBN_COMP_ATTACK_MS / 1000.0;
    double releaseSamples = sampleRate * VBN_COMP_RELEASE_MS / 1000.0;
    state->compAttackCoef = (float)exp(-1.0 / attackSamples);
    state->compReleaseCoef = (float)exp(-1.0 / releaseSamples);

    // Limiter setup
    state->limiterGain = 1.0f;
    state->lookaheadSamples = (int)(sampleRate * VBN_LIMITER_LOOKAHEAD_MS / 1000.0);
    double limiterReleaseSamples = sampleRate * VBN_LIMITER_RELEASE_MS / 1000.0;
    state->limiterReleaseCoef = 1.0f - (float)exp(-2.2 / limiterReleaseSamples);

    state->dequeIndices = (int*)calloc(VBN_DEQUE_CAPACITY, sizeof(int));
    state->dequeValues = (float*)calloc(VBN_DEQUE_CAPACITY, sizeof(float));

    return state;
}

void VBN_Destroy(VBNState* state) {
    if (!state) return;

    free(state->sampleBuffer);
    free(state->tempBuffer);
    free(state->dequeIndices);
    free(state->dequeValues);
    free(state->peakBuffer);
    free(state->gainBuffer);

    if (state->preFilterSetup) vDSP_biquad_DestroySetup(state->preFilterSetup);
    if (state->rlbFilterSetup) vDSP_biquad_DestroySetup(state->rlbFilterSetup);
    if (state->hpSetup) vDSP_biquad_DestroySetup(state->hpSetup);

    // Note: stats is freed by analysis module if enabled

    free(state);
}

void VBN_Reset(VBNState* state) {
    if (!state) return;

    // Reset LUFS state
    memset(state->sampleBuffer, 0, state->bufferSize * sizeof(float));
    state->writeIndex = 0;
    state->samplesAccumulated = 0;
    memset(state->preFilterDelays, 0, sizeof(state->preFilterDelays));
    memset(state->rlbFilterDelays, 0, sizeof(state->rlbFilterDelays));
    memset(state->blockLoudnesses, 0, sizeof(state->blockLoudnesses));
    state->blockCount = 0;
    state->currentLUFS = -24.0f;
    state->currentGain = 1.0f;
    state->targetGain = 1.0f;
    state->hasInitialMeasurement = false;

    // Reset high-pass filter
    memset(state->hpDelays, 0, sizeof(state->hpDelays));

    // Reset compressor
    memset(state->compEnvelopes, 0, sizeof(state->compEnvelopes));

    // Reset limiter
    state->limiterGain = 1.0f;
    dequeClear(state);

    // Reset temporary before-processing measurements
    state->lastBeforeRMS = -100.0f;
    state->lastBeforePeak = -100.0f;
    state->lastBeforeTruePeak = -100.0f;
}

// ============================================================================
// Main Processing
// ============================================================================

void VBN_Process(VBNState* state,
                 float* const* channels,
                 int frameCount,
                 int channelCount) {
    if (!state || !channels || frameCount <= 0 || channelCount <= 0) return;

    // Step 1: Get LUFS-based gain (measures input, returns gain to apply)
    processLUFS(state, channels, frameCount, channelCount);
    float lufsGain = state->currentGain;

    // Process each channel
    for (int ch = 0; ch < channelCount; ch++) {
        float* samples = channels[ch];

        // Step 2: Apply LUFS gain
        if (lufsGain != 1.0f) {
            vDSP_vsmul(samples, 1, &lufsGain, samples, 1, frameCount);
        }

        // Step 3: High-pass filter
        applyHighPass(state, samples, frameCount, ch);

        // Step 4: Compression
        applyCompression(state, samples, frameCount, ch);
    }

    // Step 5: True-peak limiter (processes all channels together)
    applyLimiter(state, channels, frameCount, channelCount);
}

// ============================================================================
// State Queries
// ============================================================================

float VBN_GetCurrentGainDB(const VBNState* state) {
    if (!state) return 0.0f;
    return 20.0f * log10f(fmaxf(state->currentGain, 0.001f));
}

float VBN_GetMeasuredLUFS(const VBNState* state) {
    if (!state) return -70.0f;
    return state->currentLUFS;
}

float VBN_GetLimiterReductionDB(const VBNState* state) {
    if (!state) return 0.0f;
    return 20.0f * log10f(fmaxf(state->limiterGain, 0.001f));
}

float VBN_GetTargetLUFS(const VBNState* state) {
    (void)state;
    return VBN_TARGET_LUFS;
}

// ============================================================================
// Filter Coefficient Calculation
// ============================================================================

// Calculate K-weighting filter coefficients (ITU BS.1770-4)
// Formulas from Brecht De Man's implementation matching ITU-R BS.1770-4
static void calculateLUFSFilterCoefficients(VBNState* state) {
    double sr = state->sampleRate;

    // Stage 1: High-shelf pre-filter (head model)
    // Parameters derived from ITU-R BS.1770-4 for 48kHz, scaled for other rates
    double f0_pre = 1681.9744509555319;
    double G_pre = 3.99984385397;  // dB
    double Q_pre = 0.7071752369554193;

    double K = tan(M_PI * f0_pre / sr);
    double K2 = K * K;
    double Vh = pow(10.0, G_pre / 20.0);
    double Vb = pow(Vh, 0.499666774155);  // Critical ITU-specific constant
    double a0_pre = 1.0 + K / Q_pre + K2;

    double preB[3], preA[3];
    preB[0] = (Vh + Vb * K / Q_pre + K2) / a0_pre;
    preB[1] = 2.0 * (K2 - Vh) / a0_pre;
    preB[2] = (Vh - Vb * K / Q_pre + K2) / a0_pre;
    preA[0] = 1.0;
    preA[1] = 2.0 * (K2 - 1.0) / a0_pre;
    preA[2] = (1.0 - K / Q_pre + K2) / a0_pre;

    // Stage 2: High-pass RLB filter
    double f0_rlb = 38.13547087613982;
    double Q_rlb = 0.5003270373253953;

    double Krlb = tan(M_PI * f0_rlb / sr);
    double Krlb2 = Krlb * Krlb;
    double a0_rlb = 1.0 + Krlb / Q_rlb + Krlb2;

    double rlbB[3], rlbA[3];
    rlbB[0] = 1.0;
    rlbB[1] = -2.0;
    rlbB[2] = 1.0;
    rlbA[0] = 1.0;
    rlbA[1] = 2.0 * (Krlb2 - 1.0) / a0_rlb;
    rlbA[2] = (1.0 - Krlb / Q_rlb + Krlb2) / a0_rlb;

    // Create vDSP biquad setups
    double preCoeffs[5] = { preB[0], preB[1], preB[2], preA[1], preA[2] };
    state->preFilterSetup = vDSP_biquad_CreateSetup(preCoeffs, 1);

    double rlbCoeffs[5] = { rlbB[0], rlbB[1], rlbB[2], rlbA[1], rlbA[2] };
    state->rlbFilterSetup = vDSP_biquad_CreateSetup(rlbCoeffs, 1);
}

// Calculate high-pass filter coefficients
static void calculateHighPassCoefficients(VBNState* state) {
    double w0 = 2.0 * M_PI * VBN_HP_FREQUENCY / state->sampleRate;
    double cosw0 = cos(w0);
    double sinw0 = sin(w0);
    double alpha = sinw0 / (2.0 * VBN_HP_Q);

    double b0 = (1.0 + cosw0) / 2.0;
    double b1 = -(1.0 + cosw0);
    double b2 = (1.0 + cosw0) / 2.0;
    double a0 = 1.0 + alpha;
    double a1 = -2.0 * cosw0;
    double a2 = 1.0 - alpha;

    // Normalize
    double coeffs[5] = {
        b0 / a0, b1 / a0, b2 / a0,
        a1 / a0, a2 / a0
    };

    state->hpSetup = vDSP_biquad_CreateSetup(coeffs, 1);
}

// ============================================================================
// LUFS Measurement
// ============================================================================

static void processLUFS(VBNState* restrict state, float* const* restrict channels, int frameCount, int channelCount) {
    // Ensure temp buffer is large enough
    if (state->tempBufferSize < frameCount) {
        free(state->tempBuffer);
        state->tempBuffer = (float*)malloc(frameCount * sizeof(float));
        state->tempBufferSize = frameCount;
    }

    // For LUFS measurement, use channel 0 only (left channel for stereo)
    // This is appropriate for podcasts where:
    // 1. Most content is mono or center-panned voice
    // 2. Stereo podcasts have L ≈ R for speech
    // Using a single channel avoids phase cancellation artifacts from amplitude averaging
    memcpy(state->tempBuffer, channels[0], frameCount * sizeof(float));

    // Apply K-weighting filters (ITU BS.1770-4)
    vDSP_biquad(state->preFilterSetup, state->preFilterDelays, state->tempBuffer, 1, state->tempBuffer, 1, frameCount);
    vDSP_biquad(state->rlbFilterSetup, state->rlbFilterDelays, state->tempBuffer, 1, state->tempBuffer, 1, frameCount);

    // Copy to circular buffer
    int remaining = frameCount;
    int srcOffset = 0;

    while (remaining > 0) {
        int spaceInBuffer = state->bufferSize - state->writeIndex;
        int copyCount = (remaining < spaceInBuffer) ? remaining : spaceInBuffer;

        memcpy(state->sampleBuffer + state->writeIndex,
               state->tempBuffer + srcOffset,
               copyCount * sizeof(float));

        state->writeIndex = (state->writeIndex + copyCount) & state->bufferMask;
        state->samplesAccumulated += copyCount;
        srcOffset += copyCount;
        remaining -= copyCount;

        // Measure when we cross hop boundary
        while (state->samplesAccumulated >= state->hopSize) {
            state->samplesAccumulated -= state->hopSize;
            measureBlock(state);
        }
    }

    // Gain smoothing - use fixed coefficient for smooth transitions
    // Adaptive smoothing was causing clicks due to abrupt gain changes
    state->currentGain = state->currentGain * 0.95f + state->targetGain * 0.05f;
}

static void measureBlock(VBNState* state) {
    float meanSquare = 0;
    int startIndex = (state->writeIndex - state->blockSize + state->bufferSize) & state->bufferMask;

    // Check if block is contiguous
    if (startIndex + state->blockSize <= state->bufferSize) {
        vDSP_measqv(state->sampleBuffer + startIndex, 1, &meanSquare, state->blockSize);
    } else {
        // Block wraps around
        int firstPart = state->bufferSize - startIndex;
        int secondPart = state->blockSize - firstPart;

        float sum1 = 0, sum2 = 0;
        vDSP_svesq(state->sampleBuffer + startIndex, 1, &sum1, firstPart);
        vDSP_svesq(state->sampleBuffer, 1, &sum2, secondPart);
        meanSquare = (sum1 + sum2) / (float)state->blockSize;
    }

    if (meanSquare <= 0) return;

    float blockLoudness = -0.691f + 10.0f * log10f(meanSquare);

    // Absolute gate: only include blocks above -70 LUFS
    if (blockLoudness > VBN_ABSOLUTE_THRESHOLD) {
        // Shift array if full
        if (state->blockCount >= VBN_MAX_BLOCKS) {
            memmove(state->blockLoudnesses, state->blockLoudnesses + 1, (VBN_MAX_BLOCKS - 1) * sizeof(float));
            state->blockCount = VBN_MAX_BLOCKS - 1;
        }
        state->blockLoudnesses[state->blockCount++] = blockLoudness;

        // ITU BS.1770-4 two-pass gating:
        // Pass 1: Calculate ungated loudness (blocks above absolute threshold)
        // Pass 2: Apply relative gate (-10 LU below ungated average)
        if (state->blockCount > 0) {
            // Pass 1: Ungated average (already filtered by absolute gate)
            float sumMeanSquare = 0;
            for (int i = 0; i < state->blockCount; i++) {
                sumMeanSquare += powf(10.0f, (state->blockLoudnesses[i] + 0.691f) / 10.0f);
            }
            float ungatedLUFS = -0.691f + 10.0f * log10f(sumMeanSquare / (float)state->blockCount);

            // Pass 2: Relative gate threshold
            float relativeThreshold = ungatedLUFS + VBN_RELATIVE_THRESHOLD;

            // Recalculate with relative gate applied
            float gatedSum = 0;
            int gatedCount = 0;
            for (int i = 0; i < state->blockCount; i++) {
                if (state->blockLoudnesses[i] > relativeThreshold) {
                    gatedSum += powf(10.0f, (state->blockLoudnesses[i] + 0.691f) / 10.0f);
                    gatedCount++;
                }
            }

            // Use gated measurement if we have enough blocks, otherwise use ungated
            if (gatedCount > 0) {
                state->currentLUFS = -0.691f + 10.0f * log10f(gatedSum / (float)gatedCount);
            } else {
                state->currentLUFS = ungatedLUFS;
            }

            // Calculate target gain
            float requiredGainDB = VBN_TARGET_LUFS - state->currentLUFS;

            // Clamp gain
            if (requiredGainDB > VBN_MAX_GAIN_DB) requiredGainDB = VBN_MAX_GAIN_DB;
            if (requiredGainDB < VBN_MIN_GAIN_DB) requiredGainDB = VBN_MIN_GAIN_DB;

            state->targetGain = powf(10.0f, requiredGainDB / 20.0f);
            state->hasInitialMeasurement = true;
        }
    }
}

// ============================================================================
// High-Pass Filter
// ============================================================================

static void applyHighPass(VBNState* restrict state, float* restrict samples, int frameCount, int channel) {
    if (channel >= 2 || !state->hpSetup) return;
    vDSP_biquad(state->hpSetup, state->hpDelays[channel], samples, 1, samples, 1, frameCount);
}

// ============================================================================
// Compression
// ============================================================================

static void applyCompression(VBNState* restrict state, float* restrict samples, int frameCount, int channel) {
    if (channel >= 2) return;

    float thresh = state->compThreshold;
    float slope = state->compSlope;
    float* envelope = &state->compEnvelopes[channel];

    // Vectorized early exit check
    float maxLevel = 0;
    vDSP_maxmgv(samples, 1, &maxLevel, frameCount);

    // If signal and envelope both well below threshold, skip processing
    if (maxLevel < thresh * 0.5f && *envelope < thresh * 0.5f) {
        float coef = state->compReleaseCoef;
        float effectiveCoef = powf(coef, (float)frameCount);
        *envelope = effectiveCoef * (*envelope) + (1.0f - effectiveCoef) * maxLevel;
        return;
    }

    // Pre-compute absolute values using vDSP (vectorized)
    float* absBuffer = state->peakBuffer;  // Reuse limiter buffer
    if (state->maxLimiterBufferSize < frameCount) {
        // Will be allocated by limiter, use stack for small frames
        float stackBuffer[2048];
        absBuffer = (frameCount <= 2048) ? stackBuffer : state->peakBuffer;
    }
    if (absBuffer) {
        vDSP_vabs(samples, 1, absBuffer, 1, frameCount);
    }

    float attCoef = state->compAttackCoef;
    float relCoef = state->compReleaseCoef;
    float env = *envelope;

    // Envelope follower with gain application (sequential due to feedback)
    for (int i = 0; i < frameCount; i++) {
        float inputLevel = absBuffer ? absBuffer[i] : fabsf(samples[i]);

        float coef = (inputLevel > env) ? attCoef : relCoef;
        env = coef * env + (1.0f - coef) * inputLevel;

        if (env > thresh) {
            float ratio = thresh / env;
            float gain = 1.0f - slope * (1.0f - ratio);
            if (gain < 0.1f) gain = 0.1f;
            samples[i] *= gain;
        }
    }

    *envelope = env;
}

// ============================================================================
// True-Peak Limiter
// ============================================================================

static void applyLimiter(VBNState* restrict state, float* const* restrict channels, int frameCount, int channelCount) {
    // Ensure buffers are large enough
    if (state->maxLimiterBufferSize < frameCount) {
        free(state->peakBuffer);
        free(state->gainBuffer);
        state->peakBuffer = (float*)malloc(frameCount * sizeof(float));
        state->gainBuffer = (float*)malloc(frameCount * sizeof(float));
        state->maxLimiterBufferSize = frameCount;
    }

    // Early exit: check if max signal is well below ceiling
    float maxSignal = 0;
    for (int ch = 0; ch < channelCount; ch++) {
        float chMax = 0;
        vDSP_maxmgv(channels[ch], 1, &chMax, frameCount);
        if (chMax > maxSignal) maxSignal = chMax;
    }

    if (maxSignal < VBN_LIMITER_CEILING * 0.7f && state->limiterGain > 0.99f) {
        return;  // No limiting needed
    }

    // Build peak buffer using sample peak detection
    vDSP_vabs(channels[0], 1, state->peakBuffer, 1, frameCount);
    for (int ch = 1; ch < channelCount; ch++) {
        vDSP_vabs(channels[ch], 1, state->gainBuffer, 1, frameCount);
        vDSP_vmax(state->peakBuffer, 1, state->gainBuffer, 1, state->peakBuffer, 1, frameCount);
    }

    // Initialize gain buffer to 1.0
    float one = 1.0f;
    vDSP_vfill(&one, state->gainBuffer, 1, frameCount);

    // O(n) sliding maximum using ring buffer deque
    dequeClear(state);

    for (int i = 0; i < frameCount; i++) {
        int addIdx = i + state->lookaheadSamples;
        if (addIdx < frameCount) {
            float newPeak = state->peakBuffer[addIdx];
            while (!dequeIsEmpty(state) && dequeBackVal(state) <= newPeak) {
                dequePopBack(state);
            }
            dequePushBack(state, addIdx, newPeak);
        }

        while (!dequeIsEmpty(state) && dequeFrontIdx(state) < i) {
            dequePopFront(state);
        }

        float currentPeak = state->peakBuffer[i];
        float windowMax = dequeIsEmpty(state) ? currentPeak : fmaxf(dequeFrontVal(state), currentPeak);

        if (windowMax > VBN_LIMITER_CEILING) {
            state->gainBuffer[i] = VBN_LIMITER_CEILING / windowMax;
        }
    }

    // Apply gain with instant attack, smooth release
    // Instant attack is required to catch peaks - lookahead provides smoothing
    float gainState = state->limiterGain;
    float releaseCoef = state->limiterReleaseCoef;

    for (int i = 0; i < frameCount; i++) {
        float required = state->gainBuffer[i];
        if (required < gainState) {
            gainState = required;  // Instant attack (lookahead makes this smooth)
        } else {
            gainState = gainState + releaseCoef * (1.0f - gainState);  // Smooth release
        }
        state->gainBuffer[i] = gainState;
    }

    // Apply gain to all channels
    for (int ch = 0; ch < channelCount; ch++) {
        vDSP_vmul(channels[ch], 1, state->gainBuffer, 1, channels[ch], 1, frameCount);
    }

    state->limiterGain = gainState;
}
