import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef CreateSoundTouchNative = Pointer Function();
typedef CreateSoundTouch = Pointer Function();

typedef ProcessSampleNative = Void Function(
    Pointer handle, Pointer<Float> samples, Int32 numSamples);
typedef ProcessSample = void Function(
    Pointer handle, Pointer<Float> samples, int numSamples);

typedef SetPitchSemiTonesNative = Void Function(Pointer handle, Float pitch);
typedef SetPitchSemiTones = void Function(Pointer handle, double pitch);

typedef SetTempoChangeNative = Void Function(Pointer handle, Float tempo);
typedef SetTempoChange = void Function(Pointer handle, double tempo);

typedef SetRateChangeNative = Void Function(Pointer handle, Float rate);
typedef SetRateChange = void Function(Pointer handle, double rate);

typedef ReceiveSamplesNative = Int32 Function(
    Pointer handle, Pointer<Float> output, Int32 maxSamples);
typedef ReceiveSamples = int Function(
    Pointer handle, Pointer<Float> output, int maxSamples);

typedef DisposeSoundTouchNative = Void Function(Pointer handle);
typedef DisposeSoundTouch = void Function(Pointer handle);

class SoundTouchBindings {
  late DynamicLibrary _lib;
  late CreateSoundTouch createSoundTouch;
  late ProcessSample processSample;
  late SetPitchSemiTones setPitchSemiTones;
  late SetTempoChange setTempoChange;
  late SetRateChange setRateChange;
  late ReceiveSamples receiveSamples;
  late DisposeSoundTouch disposeSoundTouch;

  SoundTouchBindings() {
    _initializeBindings();
  }

  void _initializeBindings() {
    final libraryPath = _getLibraryPath();
    print('.......Attempting to load library from: $libraryPath');
    try {
      _lib = DynamicLibrary.open(libraryPath);
      print('.....Successfully loaded library');
    } catch (e) {
      print('.....Failed to load library: $e');
      rethrow;
    }

    createSoundTouch = _lib
        .lookup<NativeFunction<CreateSoundTouchNative>>('createSoundTouch')
        .asFunction();
    processSample = _lib
        .lookup<NativeFunction<ProcessSampleNative>>('processSample')
        .asFunction();
    setPitchSemiTones = _lib
        .lookup<NativeFunction<SetPitchSemiTonesNative>>('setPitchSemiTones')
        .asFunction();
    setTempoChange = _lib
        .lookup<NativeFunction<SetTempoChangeNative>>('setTempoChange')
        .asFunction();
    setRateChange = _lib
        .lookup<NativeFunction<SetRateChangeNative>>('setRateChange')
        .asFunction();
    receiveSamples = _lib
        .lookup<NativeFunction<ReceiveSamplesNative>>('receiveSamples')
        .asFunction();
    disposeSoundTouch = _lib
        .lookup<NativeFunction<DisposeSoundTouchNative>>('disposeSoundTouch')
        .asFunction();
  }

  String _getLibraryPath() {
    if (Platform.isAndroid) {
      return 'libsoundtouch.so';
    } else if (Platform.isIOS) {
      return 'soundtouch.framework/soundtouch';
    } else if (Platform.isWindows) {
      return 'SoundTouchDLL.dll';
    } else if (Platform.isMacOS) {
      return 'libSoundTouchDLL.dylib';
    } else if (Platform.isLinux) {
      return 'libsoundtouch.so';
    }
    throw UnsupportedError('Unsupported platform');
  }
} 
