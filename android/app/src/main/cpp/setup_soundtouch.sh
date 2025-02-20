#!/bin/bash

# Exit on error
set -e

# Create soundtouch directory if it doesn't exist
mkdir -p soundtouch/source soundtouch/include

# Download SoundTouch if not already present
if [ ! -f "soundtouch/source/SoundTouch.cpp" ]; then
    echo "Downloading SoundTouch..."
    curl -L https://codeberg.org/soundtouch/soundtouch/archive/2.3.1.tar.gz -o soundtouch.tar.gz
    tar xzf soundtouch.tar.gz
    
    # Copy necessary files
    cp soundtouch-*/source/SoundTouch/*.cpp soundtouch/source/
    cp soundtouch-*/source/SoundTouch/*.h soundtouch/source/
    cp -r soundtouch-*/include/* soundtouch/include/
    
    # Cleanup
    rm -rf soundtouch-* soundtouch.tar.gz
fi

# Create CMakeLists.txt for SoundTouch
cat > soundtouch/CMakeLists.txt << 'EOL'
cmake_minimum_required(VERSION 3.10.2)

project(SoundTouch)

# Explicitly list source files
set(SOURCES
    source/AAFilter.cpp
    source/BPMDetect.cpp
    source/cpu_detect_x86.cpp
    source/FIFOSampleBuffer.cpp
    source/FIRFilter.cpp
    source/InterpolateCubic.cpp
    source/InterpolateLinear.cpp
    source/InterpolateShannon.cpp
    source/mmx_optimized.cpp
    source/PeakFinder.cpp
    source/RateTransposer.cpp
    source/SoundTouch.cpp
    source/sse_optimized.cpp
    source/TDStretch.cpp
)

# Create the library
add_library(SoundTouch STATIC ${SOURCES})

# Set include directories
target_include_directories(SoundTouch PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/source
)

# Set compiler flags
target_compile_definitions(SoundTouch PRIVATE
    SOUNDTOUCH_DISABLE_X86_OPTIMIZATIONS
    ST_NO_EXCEPTION_HANDLING=1
)

# Set C++ standard
set_target_properties(SoundTouch PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS NO
)
EOL

echo "SoundTouch setup complete" 