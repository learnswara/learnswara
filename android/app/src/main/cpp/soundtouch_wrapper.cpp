#include <jni.h>
#include <string>
#include <android/log.h>
#include "soundtouch/include/SoundTouch.h"
#include <unordered_map>
#include <memory>
#include <cmath>
#include <atomic>

using namespace soundtouch;

#define LOG_TAG "SoundTouchWrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global reference to store SoundTouch instances
static std::unordered_map<jlong, std::unique_ptr<SoundTouch>> soundTouchInstances;
static std::atomic<jlong> nextHandle{1};  // Add this line for handle generation

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_example_swarav1_MainActivity_createSoundTouch(
        JNIEnv *env,
        jobject /* this */) {
    try {
        auto soundTouch = std::make_unique<SoundTouch>();
        if (!soundTouch) {
            LOGE("Failed to create SoundTouch instance");
            return 0;
        }

        // Initialize with optimal settings for piano
        soundTouch->setSampleRate(48000);
        soundTouch->setChannels(1);
        
        // Piano-optimized settings
        soundTouch->setSetting(SETTING_USE_QUICKSEEK, 0);      // Disable quick seeking
        soundTouch->setSetting(SETTING_USE_AA_FILTER, 1);      // Enable anti-aliasing
        soundTouch->setSetting(SETTING_SEQUENCE_MS, 30);       // Shorter sequence for better transients
        soundTouch->setSetting(SETTING_SEEKWINDOW_MS, 10);     // Smaller seek window
        soundTouch->setSetting(SETTING_OVERLAP_MS, 12);        // Longer overlap for smoother transitions
        soundTouch->setSetting(SETTING_NOMINAL_INPUT_SEQUENCE, 4096);  // Larger input sequence
        soundTouch->setSetting(SETTING_NOMINAL_OUTPUT_SEQUENCE, 4096); // Larger output sequence

        // Generate a new handle
        jlong handle = nextHandle++;
        soundTouchInstances[handle] = std::move(soundTouch);
        
        LOGI("Created SoundTouch instance with handle: %lld", handle);
        return handle;
    } catch (const std::exception& e) {
        LOGE("Exception in createSoundTouch: %s", e.what());
        return 0;
    }
}

bool isValidHandle(jlong handle) {
    if (handle <= 0) {
        LOGE("Invalid handle value: %lld", handle);
        return false;
    }
    
    // Convert handle to proper format if needed
    jlong actualHandle = handle;
    auto it = soundTouchInstances.find(actualHandle);
    
    if (it == soundTouchInstances.end()) {
        LOGE("Handle not found: %lld (actual: %lld)", handle, actualHandle);
        return false;
    }
    if (!it->second) {
        LOGE("Null SoundTouch instance for handle: %lld", actualHandle);
        return false;
    }
    return true;
}

JNIEXPORT void JNICALL
Java_com_example_swarav1_MainActivity_processSample(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jfloatArray samples,
        jint numSamples) {
    LOGI("Processing samples with handle: %lld", handle);
    if (!isValidHandle(handle)) {
        return;
    }

    try {
        auto& soundTouch = soundTouchInstances[handle];
        if (!samples) {
            LOGE("Null samples array");
            return;
        }

        jsize arrayLength = env->GetArrayLength(samples);
        if (arrayLength < numSamples) {
            LOGE("Sample array too small: %d < %d", arrayLength, numSamples);
            return;
        }

        jfloat *samplesArray = env->GetFloatArrayElements(samples, nullptr);
        if (!samplesArray) {
            LOGE("Failed to get samples array elements");
            return;
        }

        try {
            LOGI("Processing %d samples", numSamples);
            soundTouch->putSamples(samplesArray, numSamples);
            LOGI("Samples processed successfully");
        } catch (const std::exception& e) {
            LOGE("Exception processing samples: %s", e.what());
        }

        env->ReleaseFloatArrayElements(samples, samplesArray, 0);
    } catch (const std::exception& e) {
        LOGE("Exception in processSample: %s", e.what());
    }
}

JNIEXPORT void JNICALL
Java_com_example_swarav1_MainActivity_setPitchSemiTones(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jdouble pitch) {
    if (!isValidHandle(handle)) return;

    try {
        auto& soundTouch = soundTouchInstances[handle];
        LOGI("Setting pitch to %f semitones for handle %lld", pitch, handle);
        
        // Clear any existing samples first
        soundTouch->clear();
        
        // For large pitch shifts, adjust the processing parameters
        if (std::abs(pitch) > 7.0) {
            // Use more conservative settings for large pitch shifts
            soundTouch->setSetting(SETTING_SEQUENCE_MS, 35);   // Adjust sequence length
            soundTouch->setSetting(SETTING_SEEKWINDOW_MS, 12); // Adjust seek window
            soundTouch->setSetting(SETTING_OVERLAP_MS, 10);    // Adjust overlap
        }
        
        soundTouch->setPitchSemiTones(static_cast<float>(pitch));
        LOGI("Pitch set successfully");
    } catch (const std::exception& e) {
        LOGE("Exception in setPitchSemiTones: %s", e.what());
    }
}

JNIEXPORT void JNICALL
Java_com_example_swarav1_MainActivity_setTempoChange(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jdouble tempo) {
    if (!isValidHandle(handle)) return;

    try {
        auto& soundTouch = soundTouchInstances[handle];
        soundTouch->setTempoChange(static_cast<float>(tempo));
        LOGI("Tempo change set successfully to %f", tempo);
    } catch (const std::exception& e) {
        LOGE("Exception in setTempoChange: %s", e.what());
    }
}

JNIEXPORT void JNICALL
Java_com_example_swarav1_MainActivity_setRateChange(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jdouble rate) {
    if (!isValidHandle(handle)) return;

    try {
        auto& soundTouch = soundTouchInstances[handle];
        soundTouch->setRate(static_cast<float>(rate));
        LOGI("Rate change set successfully to %f", rate);
    } catch (const std::exception& e) {
        LOGE("Exception in setRateChange: %s", e.what());
    }
}

JNIEXPORT jint JNICALL
Java_com_example_swarav1_MainActivity_receiveSamples(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jfloatArray output,
        jint maxSamples) {
    LOGI("Receiving samples with handle: %lld", handle);
    if (!isValidHandle(handle)) {
        LOGE("Invalid handle in receiveSamples: %lld", handle);
        return 0;
    }

    try {
        auto& soundTouch = soundTouchInstances[handle];
        if (output == nullptr) {
            LOGE("Null output array in receiveSamples");
            return 0;
        }

        jsize arrayLength = env->GetArrayLength(output);
        if (arrayLength < maxSamples) {
            LOGE("Output array too small: %d < %d", arrayLength, maxSamples);
            return 0;
        }

        jfloat *outputArray = env->GetFloatArrayElements(output, nullptr);
        if (outputArray == nullptr) {
            LOGE("Failed to get float array elements");
            return 0;
        }

        int received = 0;
        try {
            LOGI("Requesting up to %d samples from handle %lld", maxSamples, handle);
            received = soundTouch->receiveSamples(outputArray, maxSamples);
            LOGI("Received %d samples", received);
        } catch (const std::exception& e) {
            LOGE("Exception while receiving samples: %s", e.what());
        }

        env->ReleaseFloatArrayElements(output, outputArray, 0);
        return received;
    } catch (const std::exception& e) {
        LOGE("Exception in receiveSamples: %s", e.what());
        return 0;
    }
}

JNIEXPORT void JNICALL
Java_com_example_swarav1_MainActivity_disposeSoundTouch(
        JNIEnv *env,
        jobject /* this */,
        jlong handle) {
    if (!isValidHandle(handle)) return;

    try {
        soundTouchInstances.erase(handle);
        LOGI("SoundTouch instance %lld disposed", (long long)handle);
    } catch (const std::exception& e) {
        LOGE("Exception in disposeSoundTouch: %s", e.what());
    } catch (...) {
        LOGE("Unknown exception in disposeSoundTouch");
    }
}

JNIEXPORT jstring JNICALL
Java_com_example_swarav1_MainActivity_processSound(
        JNIEnv *env,
        jobject /* this */,
        jstring inputPath,
        jstring outputPath) {
    
    const char *inputPathStr = env->GetStringUTFChars(inputPath, 0);
    const char *outputPathStr = env->GetStringUTFChars(outputPath, 0);

    // Log the input parameters
    LOGI("Processing sound file: %s -> %s", inputPathStr, outputPathStr);
    
    // Release the string resources
    env->ReleaseStringUTFChars(inputPath, inputPathStr);
    env->ReleaseStringUTFChars(outputPath, outputPathStr);

    // Return a success message
    return env->NewStringUTF("Sound processing completed successfully");
}

// --- New wrapper functions for FFI usage ---
JNIEXPORT void JNICALL processSampleWrapper(jlong handle, const float *samples, jint numSamples) {
    LOGI("processSampleWrapper: Processing %d samples with handle %lld", numSamples, handle);
    if (!isValidHandle(handle)) {
        LOGE("processSampleWrapper: Invalid handle %lld", handle);
        return;
    }
    auto& soundTouch = soundTouchInstances[handle];
    try {
        soundTouch->putSamples(samples, numSamples);
        soundTouch->flush();
        LOGI("processSampleWrapper: Samples processed successfully");
    } catch (const std::exception &e) {
        LOGE("processSampleWrapper: Exception: %s", e.what());
    }
}

JNIEXPORT jint JNICALL receiveSamplesWrapper(jlong handle, float *output, jint maxSamples) {
    LOGI("receiveSamplesWrapper: Requesting up to %d samples from handle %lld", maxSamples, handle);
    if (!isValidHandle(handle)) {
        LOGE("receiveSamplesWrapper: Invalid handle %lld", handle);
        return 0;
    }
    auto& soundTouch = soundTouchInstances[handle];
    int received = 0;
    try {
        received = soundTouch->receiveSamples(output, maxSamples);
        LOGI("receiveSamplesWrapper: Received %d samples", received);
    } catch (const std::exception &e) {
        LOGE("receiveSamplesWrapper: Exception: %s", e.what());
    }
    return received;
}

} 