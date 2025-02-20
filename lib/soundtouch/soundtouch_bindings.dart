import 'dart:ffi';
import 'dart:io';

typedef CreateSoundTouchNative = Int64 Function();
typedef CreateSoundTouch = int Function();

typedef ProcessSampleNative = Void Function(
    Int64 handle, Pointer<Float> samples, Int32 numSamples);
typedef ProcessSampleWrapper = void Function(
    int handle, Pointer<Float> samples, int numSamples);
typedef ProcessSampleWrapperNative = Void Function(
    Int64 handle, Pointer<Float> samples, Int32 numSamples);

typedef SetPitchSemiTonesNative = Void Function(Int64 handle, Double pitch);
typedef SetPitchSemiTones = void Function(int handle, double pitch);

typedef SetTempoChangeNative = Void Function(Int64 handle, Double tempo);
typedef SetTempoChange = void Function(int handle, double tempo);

typedef SetRateChangeNative = Void Function(Int64 handle, Double rate);
typedef SetRateChange = void Function(int handle, double rate);

typedef ReceiveSamplesNative = Int32 Function(
    Int64 handle, Pointer<Float> output, Int32 maxSamples);
typedef ReceiveSamplesWrapper = int Function(
    int handle, Pointer<Float> output, int maxSamples);
typedef ReceiveSamplesWrapperNative = Int32 Function(
    Int64 handle, Pointer<Float> output, Int32 maxSamples);

typedef DisposeSoundTouchNative = Void Function(Int64 handle);
typedef DisposeSoundTouch = void Function(int handle);

class SoundTouchBindings {
  final DynamicLibrary _lib;
  late final CreateSoundTouch createSoundTouch;
  late final ProcessSampleWrapper processSample;
  late final SetPitchSemiTones setPitchSemiTones;
  late final SetTempoChange setTempoChange;
  late final SetRateChange setRateChange;
  late final ReceiveSamplesWrapper receiveSamples;
  late final DisposeSoundTouch disposeSoundTouch;

  SoundTouchBindings() : _lib = _openLib() {
    _initializeBindings();
  }

  static DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libsoundtouch_wrapper.so');
    }
    throw UnsupportedError('Unsupported platform');
  }

  void _initializeBindings() {
    createSoundTouch = _lib
        .lookupFunction<CreateSoundTouchNative, CreateSoundTouch>(
            'Java_com_example_swarav1_MainActivity_createSoundTouch');
    
    processSample = _lib
        .lookupFunction<ProcessSampleWrapperNative, ProcessSampleWrapper>(
            "processSampleWrapper");
    
    receiveSamples = _lib
        .lookupFunction<ReceiveSamplesWrapperNative, ReceiveSamplesWrapper>(
            "receiveSamplesWrapper");
    
    setPitchSemiTones = _lib
        .lookupFunction<SetPitchSemiTonesNative, SetPitchSemiTones>(
            'Java_com_example_swarav1_MainActivity_setPitchSemiTones');
    
    setTempoChange = _lib
        .lookupFunction<SetTempoChangeNative, SetTempoChange>(
            'Java_com_example_swarav1_MainActivity_setTempoChange');
    
    setRateChange = _lib
        .lookupFunction<SetRateChangeNative, SetRateChange>(
            'Java_com_example_swarav1_MainActivity_setRateChange');
    
    disposeSoundTouch = _lib
        .lookupFunction<DisposeSoundTouchNative, DisposeSoundTouch>(
            'Java_com_example_swarav1_MainActivity_disposeSoundTouch');
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
