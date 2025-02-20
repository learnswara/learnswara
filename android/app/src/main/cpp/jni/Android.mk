LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := soundtouch
LOCAL_SRC_FILES := $(LOCAL_PATH)/../lib/libsoundtouch.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := soundtouch_wrapper
LOCAL_SRC_FILES := $(LOCAL_PATH)/../lib/libsoundtouch_wrapper.so
LOCAL_SHARED_LIBRARIES := soundtouch
include $(PREBUILT_SHARED_LIBRARY) 