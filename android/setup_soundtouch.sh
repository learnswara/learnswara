#!/bin/bash

# Navigate to the cpp directory
cd app/src/main/cpp

# Clone SoundTouch if not already present
if [ ! -d "soundtouch" ]; then
    git clone https://codeberg.org/soundtouch/soundtouch.git
    cd soundtouch
    # Checkout a stable version
    git checkout 2.3.1
    cd ..
fi

# Create include directory if it doesn't exist
mkdir -p include

# Copy necessary header files
cp soundtouch/include/*.h include/ 