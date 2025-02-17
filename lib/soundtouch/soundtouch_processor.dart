import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'soundtouch_bindings.dart';

class SoundTouchProcessor {
  final SoundTouchBindings _bindings;
  late Pointer _handle;

  SoundTouchProcessor() : _bindings = SoundTouchBindings() {
    _handle = _bindings.createSoundTouch();
  }

  void processSamples(List<double> samples) {
    final pointer = calloc<Float>(samples.length);
    for (var i = 0; i < samples.length; i++) {
      pointer[i] = samples[i];
    }
    _bindings.processSample(_handle, pointer, samples.length);
    calloc.free(pointer);
  }

  void setPitch(double semitones) {
    _bindings.setPitchSemiTones(_handle, semitones);
  }

  void setTempo(double tempo) {
    _bindings.setTempoChange(_handle, tempo);
  }

  void setRate(double rate) {
    _bindings.setRateChange(_handle, rate);
  }

  List<double> receiveSamples(int maxSamples) {
    final pointer = calloc<Float>(maxSamples);
    final receivedSamples = _bindings.receiveSamples(_handle, pointer, maxSamples);
    
    final result = List<double>.generate(
        receivedSamples, (index) => pointer[index].toDouble());
    
    calloc.free(pointer);
    return result;
  }

  void dispose() {
    _bindings.disposeSoundTouch(_handle);
  }
} 
