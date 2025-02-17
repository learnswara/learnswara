#include <jni.h>
#include <string>
#include <android/log.h>

#define LOG_TAG "SoundTouchWrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

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

    // TODO: Implement actual sound processing using SoundTouch library
    
    // Release the string resources
    env->ReleaseStringUTFChars(inputPath, inputPathStr);
    env->ReleaseStringUTFChars(outputPath, outputPathStr);

    // Return a success message
    return env->NewStringUTF("Sound processing completed successfully");
}

} 