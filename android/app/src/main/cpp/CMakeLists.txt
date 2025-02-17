cmake_minimum_required(VERSION 3.10.2)

project("swarav1")

# Find Android log library
find_library(log-lib log)

# Add SoundTouch library
add_library(soundtouch STATIC
    soundtouch/SoundTouch/AAFilter.cpp
    soundtouch/SoundTouch/FIFOSampleBuffer.cpp
    soundtouch/SoundTouch/FIRFilter.cpp
    soundtouch/SoundTouch/RateTransposer.cpp
    soundtouch/SoundTouch/SoundTouch.cpp
    soundtouch/SoundTouch/TDStretch.cpp
    soundtouch/SoundTouch/cpu_detect_x86.cpp
    soundtouch/SoundTouch/InterpolateLinear.cpp
    soundtouch/SoundTouch/BPMDetect.cpp
    soundtouch/SoundTouch/PeakFinder.cpp
)

# Set SoundTouch include directories
target_include_directories(soundtouch PUBLIC
    soundtouch/include
    soundtouch/SoundTouch
)

# Set SoundTouch compile definitions
target_compile_definitions(soundtouch PUBLIC
    SOUNDTOUCH_FLOAT_SAMPLES=1
    ST_NO_EXCEPTION_HANDLING=1
    ANDROID=1
)

# Add your wrapper library
add_library(soundtouch_wrapper SHARED
    soundtouch_wrapper.cpp
)

# Include directories for wrapper
target_include_directories(soundtouch_wrapper PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}
    soundtouch/include
)

# Link libraries
target_link_libraries(soundtouch_wrapper
    soundtouch
    ${log-lib}
    android
) 