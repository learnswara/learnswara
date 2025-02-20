import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'soundtouch_bindings.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class SoundTouchProcessor {
  final SoundTouchBindings _bindings;

  SoundTouchProcessor() : _bindings = SoundTouchBindings();

  int createSoundTouch() {
    try {
      final handle = _bindings.createSoundTouch();
      if (handle == 0) {
        throw Exception('Failed to create SoundTouch instance');
      }
      print('Created SoundTouch instance with handle: $handle');
      return handle;
    } catch (e) {
      print('Error creating SoundTouch instance: $e');
      rethrow;
    }
  }

  void setPitch(int handle, double semitones) {
    if (handle <= 0) {
      throw Exception('Invalid SoundTouch handle: $handle');
    }
    print('Setting pitch to $semitones semitones for handle: $handle (hex: ${handle.toRadixString(16)})');
    try {
      _bindings.setPitchSemiTones(handle, semitones);
    } catch (e) {
      print('Error setting pitch: $e');
      rethrow;
    }
  }

  void setTempo(int handle, double tempo) {
    if (handle <= 0) {
      throw Exception('Invalid SoundTouch handle: $handle');
    }
    print('Setting tempo to $tempo for handle: $handle');
    _bindings.setTempoChange(handle, tempo);
  }

  void setRate(int handle, double rate) {
    if (handle <= 0) {
      throw Exception('Invalid SoundTouch handle: $handle');
    }
    print('Setting rate to $rate for handle: $handle');
    _bindings.setRateChange(handle, rate);
  }

  Future<String> processAudioFile(int handle, String inputPath, String outputFileName) async {
    if (handle <= 0) {
      throw Exception('Invalid SoundTouch handle: $handle');
    }
    
    print('Processing with handle: $handle (hex: ${handle.toRadixString(16)})');
    
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/$outputFileName';

      // Read WAV file
      final ByteData inputData = await rootBundle.load(inputPath);
      final List<int> inputBytes = inputData.buffer.asUint8List();

      // Parse WAV header
      if (inputBytes.length < 44) {
        throw Exception('Invalid WAV file: too small');
      }

      // Extract WAV header information
      final sampleRate = inputBytes[24] + (inputBytes[25] << 8) + (inputBytes[26] << 16) + (inputBytes[27] << 24);
      final numChannels = inputBytes[22] + (inputBytes[23] << 8);
      
      print('Processing WAV: rate=$sampleRate, channels=$numChannels');

      // Skip WAV header and convert to float samples
      final samples = <double>[];
      for (var i = 44; i < inputBytes.length; i += 2) {
        if (i + 1 < inputBytes.length) {
          // Convert from little-endian 16-bit to float
          final int sample = (inputBytes[i + 1] << 8) | inputBytes[i];
          // Convert to float in range [-1, 1]
          samples.add(sample / 32768.0);
        }
      }

      print('Processing ${samples.length} samples');

      // Process samples through SoundTouch
      final samplesPointer = calloc<Float>(samples.length);
      try {
        // Copy samples to native memory
        for (var i = 0; i < samples.length; i++) {
          samplesPointer[i] = samples[i];
        }

        // Process through SoundTouch
        final samplesPerChannel = samples.length ~/ numChannels;
        print('Processing $samplesPerChannel samples per channel');
        
        // Create float array for output
        final maxOutputSamples = (samples.length * 2);
        final outputSamples = calloc<Float>(maxOutputSamples);
        
        try {
          // Process samples in chunks to avoid buffer issues
          final chunkSize = 4096; 
          for (var offset = 0; offset < samplesPerChannel; offset += chunkSize) {
            final currentChunkSize = (offset + chunkSize > samplesPerChannel)
                ? samplesPerChannel - offset 
                : chunkSize;
            print('Processing chunk of $currentChunkSize samples at offset $offset');
            _bindings.processSample(
                handle,
                samplesPointer.elementAt(offset * numChannels),
                currentChunkSize);
          }
          
          // Receive processed samples
          var totalReceived = 0;
          final maxSamplesPerChannel = maxOutputSamples ~/ numChannels;
          
          while (true) {
            final received = _bindings.receiveSamples(
                handle,
                outputSamples.elementAt(totalReceived * numChannels),
                maxSamplesPerChannel - totalReceived);
            if (received <= 0) break;
            totalReceived += received;
            print('Received $received samples (total: $totalReceived)');
          }
          
          if (totalReceived <= 0) {
            throw Exception('No samples received from SoundTouch (handle: $handle)');
          }

          // Create output WAV file
          final outputFile = File(outputPath);
          final sink = outputFile.openSync(mode: FileMode.write);
          
          try {
            // Calculate sizes
            final dataSize = totalReceived * numChannels * 2; // 2 bytes per sample
            final fileSize = 44 + dataSize; // WAV header + data

            // Write WAV header
            final header = ByteData(44)
              ..setUint32(0, 0x46464952, Endian.little) // 'RIFF'
              ..setUint32(4, fileSize - 8, Endian.little) // File size - 8
              ..setUint32(8, 0x45564157, Endian.little) // 'WAVE'
              ..setUint32(12, 0x20746D66, Endian.little) // 'fmt '
              ..setUint32(16, 16, Endian.little) // Format chunk size
              ..setUint16(20, 1, Endian.little) // PCM format
              ..setUint16(22, numChannels, Endian.little) // Channels
              ..setUint32(24, sampleRate, Endian.little) // Sample rate
              ..setUint32(28, sampleRate * numChannels * 2, Endian.little) // Byte rate
              ..setUint16(32, numChannels * 2, Endian.little) // Block align
              ..setUint16(34, 16, Endian.little) // Bits per sample
              ..setUint32(36, 0x61746164, Endian.little) // 'data'
              ..setUint32(40, dataSize, Endian.little); // Data chunk size

            sink.writeFromSync(header.buffer.asUint8List());

            // Convert and write audio samples
            final processedBytes = Uint8List(dataSize);
            for (var i = 0; i < totalReceived * numChannels; i++) {
              // Convert float to 16-bit integer
              final sample = (outputSamples[i] * 32767.0).round().clamp(-32768, 32767);
              processedBytes[i * 2] = sample & 0xFF;
              processedBytes[i * 2 + 1] = (sample >> 8) & 0xFF;
            }
            sink.writeFromSync(processedBytes);

            print('Successfully wrote WAV file: $outputPath ($fileSize bytes)');
            return outputPath;
          } finally {
            sink.closeSync();
          }
        } finally {
          calloc.free(outputSamples);
        }
      } finally {
        calloc.free(samplesPointer);
      }
    } catch (e, stack) {
      print('Error processing audio file: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  void disposeSoundTouch(int handle) {
    if (handle != 0) {
      _bindings.disposeSoundTouch(handle);
    }
  }
} 
