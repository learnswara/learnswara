#pragma once

#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <string>
#include <fstream>

// Add these before any other includes
extern "C" {
    #include <string.h>
    #include <stdlib.h>
    #include <math.h>
}

class WavReader {
public:
    explicit WavReader(const std::string& filename);
    ~WavReader();

    bool isValid() const { return m_valid; }
    uint32_t getSampleRate() const { return m_sampleRate; }
    uint16_t getNumChannels() const { return m_numChannels; }
    uint16_t getBitsPerSample() const { return m_bitsPerSample; }

    size_t readSamples(float* buffer, size_t maxSamples);

private:
    std::ifstream m_file;
    bool m_valid;
    uint32_t m_sampleRate;
    uint16_t m_numChannels;
    uint16_t m_bitsPerSample;
    uint32_t m_dataSize;
}; 