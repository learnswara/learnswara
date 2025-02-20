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

class WavWriter {
public:
    WavWriter(const std::string& filename, uint32_t sampleRate, 
              uint16_t numChannels, uint16_t bitsPerSample);
    ~WavWriter();

    bool isValid() const { return m_valid; }
    void writeSamples(const float* buffer, size_t numSamples);

private:
    std::ofstream m_file;
    bool m_valid;
    uint32_t m_dataSize;
    void writeHeader();
}; 