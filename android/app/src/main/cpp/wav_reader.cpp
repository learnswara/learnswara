#include "wav_reader.h"
#include <cstring>
#include <vector>

struct WavHeader {
    char riff[4];
    uint32_t fileSize;
    char wave[4];
    char fmt[4];
    uint32_t fmtLength;
    uint16_t formatTag;
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t bytesPerSecond;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
};

WavReader::WavReader(const std::string& filename) 
    : m_valid(false), m_sampleRate(0), m_numChannels(0), m_bitsPerSample(0), m_dataSize(0) {
    m_file.open(filename, std::ios::binary);
    if (!m_file.is_open()) return;

    WavHeader header;
    m_file.read(reinterpret_cast<char*>(&header), sizeof(WavHeader));

    if (strncmp(header.riff, "RIFF", 4) != 0 || 
        strncmp(header.wave, "WAVE", 4) != 0 ||
        strncmp(header.fmt, "fmt ", 4) != 0) {
        return;
    }

    m_sampleRate = header.sampleRate;
    m_numChannels = header.numChannels;
    m_bitsPerSample = header.bitsPerSample;

    // Find data chunk
    char chunkId[4];
    uint32_t chunkSize;
    while (m_file.read(chunkId, 4)) {
        m_file.read(reinterpret_cast<char*>(&chunkSize), 4);
        if (strncmp(chunkId, "data", 4) == 0) {
            m_dataSize = chunkSize;
            m_valid = true;
            break;
        }
        m_file.seekg(chunkSize, std::ios::cur);
    }
}

WavReader::~WavReader() {
    if (m_file.is_open()) {
        m_file.close();
    }
}

size_t WavReader::readSamples(float* buffer, size_t maxSamples) {
    if (!m_valid || !m_file.is_open()) return 0;

    std::vector<int16_t> tempBuffer(maxSamples);
    m_file.read(reinterpret_cast<char*>(tempBuffer.data()), maxSamples * sizeof(int16_t));
    size_t samplesRead = m_file.gcount() / sizeof(int16_t);

    for (size_t i = 0; i < samplesRead; ++i) {
        buffer[i] = tempBuffer[i] / 32768.0f;
    }

    return samplesRead;
} 