cmake_minimum_required(VERSION 3.10.2)

# Set the project name
project(soundtouch_wrapper)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find the Android NDK
include_directories(${ANDROID_NDK}/sources/android/native_app_glue)

# Add SoundTouch library
add_subdirectory(soundtouch)

# Create the native library
add_library(soundtouch_wrapper SHARED
    soundtouch_wrapper.cpp
)

# Find Android log library
find_library(log-lib log)

# Set include directories
target_include_directories(soundtouch_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/soundtouch/include
    ${CMAKE_CURRENT_SOURCE_DIR}/soundtouch/source
)

# Link against required libraries
target_link_libraries(soundtouch_wrapper
    SoundTouch
    ${log-lib}
    android
) 