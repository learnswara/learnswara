#!/bin/bash

# Create directories if they don't exist
mkdir -p soundtouch

# Download SoundTouch source
curl -L https://codeberg.org/soundtouch/soundtouch/archive/2.3.2.tar.gz -o soundtouch.tar.gz

# Extract the source
tar xzf soundtouch.tar.gz --strip-components=1 -C soundtouch

# Clean up
rm soundtouch.tar.gz

# Create directories
mkdir -p soundtouch/include
mkdir -p soundtouch/SoundTouch

# Copy header files to include directory
cp soundtouch/include/SoundTouch/*.h soundtouch/include/
cp soundtouch/include/STTypes.h soundtouch/include/

# Copy source files to SoundTouch directory
cp soundtouch/source/SoundTouch/*.cpp soundtouch/SoundTouch/
cp soundtouch/source/SoundTouch/*.h soundtouch/SoundTouch/

# Clean up unnecessary directories
rm -rf soundtouch/source
rm -rf soundtouch/config
rm -rf soundtouch/doc
rm -rf soundtouch/include/SoundTouch 