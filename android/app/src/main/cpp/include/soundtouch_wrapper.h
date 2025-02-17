#ifndef SOUNDTOUCH_WRAPPER_H
#define SOUNDTOUCH_WRAPPER_H

#include <jni.h>

extern "C" {
    JNIEXPORT jstring JNICALL
    Java_com_example_swarav1_MainActivity_processSound(
            JNIEnv *env,
            jobject thiz,
            jstring inputPath,
            jstring outputPath);
}

#endif // SOUNDTOUCH_WRAPPER_H 