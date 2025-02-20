import numpy as np
from scipy.io import wavfile

# Create a simple sine wave
sample_rate = 44100
duration = 1.0  # seconds
t = np.linspace(0, duration, int(sample_rate * duration))
frequency = 440.0  # Hz (A4 note)
samples = np.sin(2 * np.pi * frequency * t)

# Convert to 16-bit PCM
samples = (samples * 32767).astype(np.int16)

# Save as mono WAV file
wavfile.write('assets/audio/base_ultra_small_mono.wav', sample_rate, samples) 