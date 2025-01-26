cmake_minimum_required(VERSION 3.10)
project(soundtouch)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Explicitly set to build shared library (.so)
set(BUILD_SHARED_LIBS ON)

# Source files
file(GLOB SOUNDTOUCH_SOURCES
    "source/*.cpp"
    "source/SoundTouch/*.cpp"
)

# Create shared library
add_library(SoundTouchDLL SHARED ${SOUNDTOUCH_SOURCES})

# Set library properties
set_target_properties(SoundTouchDLL PROPERTIES
    OUTPUT_NAME "soundtouch"  # This will create libsoundtouch.so
    PREFIX "lib"
    SUFFIX ".so"
)

# Include directories
target_include_directories(SoundTouchDLL PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/source/SoundTouch
)

# Install rules
install(TARGETS SoundTouchDLL
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
    RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
)

# Install headers
install(FILES
    include/BPMDetect.h
    include/FIFOSampleBuffer.h
    include/FIFOSamplePipe.h
    include/STTypes.h
    include/SoundTouch.h
    include/soundtouch_config.h
    DESTINATION ${CMAKE_INSTALL_PREFIX}/include/soundtouch
)
