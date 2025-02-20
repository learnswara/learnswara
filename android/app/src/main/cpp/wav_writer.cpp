#include "wav_writer.h"
#include <vector>

struct WavHeader {
    char riff[4] = {'R', 'I', 'F', 'F'};
    uint32_t fileSize = 0;
    char wave[4] = {'W', 'A', 'V', 'E'};
    char fmt[4] = {'f', 'm', 't', ' '};
    uint32_t fmtLength = 16;
    uint16_t formatTag = 1;  // PCM
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t bytesPerSecond;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
    char data[4] = {'d', 'a', 't', 'a'};
    uint32_t dataSize = 0;
};

WavWriter::WavWriter(const std::string& filename, uint32_t sampleRate, 
                     uint16_t numChannels, uint16_t bitsPerSample)
    : m_valid(false), m_dataSize(0) {
    m_file.open(filename, std::ios::binary);
    if (!m_file.is_open()) return;

    WavHeader header;
    header.numChannels = numChannels;
    header.sampleRate = sampleRate;
    header.bitsPerSample = bitsPerSample;
    header.blockAlign = numChannels * (bitsPerSample / 8);
    header.bytesPerSecond = sampleRate * header.blockAlign;

    m_file.write(reinterpret_cast<const char*>(&header), sizeof(WavHeader));
    m_valid = true;
}

WavWriter::~WavWriter() {
    if (m_file.is_open()) {
        writeHeader();
        m_file.close();
    }
}

void WavWriter::writeSamples(const float* buffer, size_t numSamples) {
    if (!m_valid || !m_file.is_open()) return;

    std::vector<int16_t> tempBuffer(numSamples);
    for (size_t i = 0; i < numSamples; ++i) {
        tempBuffer[i] = static_cast<int16_t>(buffer[i] * 32767.0f);
    }

    m_file.write(reinterpret_cast<const char*>(tempBuffer.data()), 
                 numSamples * sizeof(int16_t));
    m_dataSize += numSamples * sizeof(int16_t);
}

void WavWriter::writeHeader() {
    if (!m_valid || !m_file.is_open()) return;

    m_file.seekp(0, std::ios::beg);
    WavHeader header;
    header.fileSize = m_dataSize + sizeof(WavHeader) - 8;
    header.dataSize = m_dataSize;
    m_file.write(reinterpret_cast<const char*>(&header), sizeof(WavHeader));
} 