import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'soundtouch/soundtouch_processor.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ffi';  // Add this import at the top

extension AudioPlayerExtension on AudioPlayer {
  Future<String?> getCurrentAudioPath() async {
    try {
      if (audioSource != null) {
        // For assets, return the asset path directly
        return 'assets/audio/test_mono.wav';
      }
      return null;
    } catch (e) {
      print('Error getting audio path: $e');
      return null;
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundTouch Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.soundtouch/native');
  String? inputFilePath;
  String? outputFilePath;
  String status = 'Ready to play';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SoundTouchProcessor _processor = SoundTouchProcessor();
  int? _handle;  // Change from Pointer? to int?

  @override
  void initState() {
    super.initState();
    _initializeSoundTouch();
    requestPermissions();
    // Load the audio file when the app starts
    _loadAudio();
  }

  void _initializeSoundTouch() {
    try {
      _handle = _processor.createSoundTouch();
      if (_handle == 0) {
        print("Failed to create SoundTouch instance");
        return;
      }
      print("Created SoundTouch instance with handle: $_handle");
    } catch (e) {
      print("Error initializing SoundTouch: $e");
    }
  }

  @override
  void dispose() {
    if (_handle != null) {
      _processor.disposeSoundTouch(_handle!);
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    try {
      const assetPath = 'assets/audio/test_mono.wav';
      // Check if asset exists
      final ByteData data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) {
        throw Exception('Asset file is empty');
      }
      
      await _audioPlayer.setAsset(assetPath);
      setState(() {
        status = 'Audio loaded and ready to play';
      });
    } catch (e) {
      print('Error loading audio: $e');
      setState(() {
        status = 'Error loading audio: $e';
      });
    }
  }

  Future<void> processSound() async {
    if (inputFilePath == null || outputFilePath == null) {
      setState(() {
        status = 'Please select an input file first';
      });
      return;
    }

    try {
      final String result = await platform.invokeMethod('processSound', {
        'inputPath': inputFilePath,
        'outputPath': outputFilePath,
      });
      setState(() {
        status = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        status = 'Failed to process sound: ${e.message}';
      });
    }
  }

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.audio.request();
  }

  Future<void> playAudioWithPitch(double pitch) async {
    print("Starting playAudioWithPitch with pitch: $pitch");
    if (_handle == null || _handle == 0) {
      print("Handle is null or invalid!");
      setState(() {
        status = 'Error: SoundTouch not initialized';
      });
      return;
    }

    print("Using handle: $_handle");

    try {
      // Calculate better tempo and rate values based on pitch shift amount
      double tempo;
      double rate;
      
      if (pitch == 8.0) {  // G#
        // For G#, use these settings
        tempo = 0.95;      // Slightly slower tempo
        rate = 0.98;       // Slightly slower rate
        print("Setting G# configuration...");
      } else if (pitch == 11.0) {  // B
        // For B, use these settings
        tempo = 0.92;      // Even slower tempo
        rate = 0.95;       // Slower rate
        print("Setting B configuration...");
      } else if (pitch == 2.0) {  // C# to D#
        // For a small shift, use default settings
        tempo = 1.0;
        rate = 1.0;
        print("Setting 2 semitones configuration...");
      } else {
        tempo = 1.0;
        rate = 1.0;
      }

      // First clear any previous processing
      _processor.disposeSoundTouch(_handle!);
      _handle = _processor.createSoundTouch();
      
      // Configure SoundTouch settings in specific order
      print("Setting rate to $rate...");
      _processor.setRate(_handle!, rate);
      
      print("Setting tempo to $tempo...");
      _processor.setTempo(_handle!, tempo);
      
      print("Setting pitch to $pitch semitones...");
      _processor.setPitch(_handle!, pitch);

      // Process the audio file
      print("Processing audio file...");
      final String processedPath = await _processor.processAudioFile(
        _handle!,
        'assets/audio/test_mono.wav',
        'output_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      print("Processed path: $processedPath");

      // Verify the file exists
      final file = File(processedPath);
      if (!file.existsSync()) {
        throw Exception('Processed file does not exist: $processedPath');
      }
      print("File size: ${file.lengthSync()} bytes");

      // Debug the audio file
      print("Audio file exists: ${file.existsSync()}");
      print("Audio file size: ${file.lengthSync()} bytes");
      print("Audio file path: ${file.absolute.path}");

      // Try to read the first few bytes
      final bytes = await file.openRead(0, 12).toList();
      print("First 12 bytes: ${bytes.expand((x) => x).toList()}");

      // Play the processed audio
      print("Setting up audio player...");
      await _audioPlayer.stop();
      
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      
      // Try playing with different audio sources
      try {
        await _audioPlayer.setAudioSource(
          AudioSource.file(processedPath),
          initialPosition: Duration.zero,
        );
        print("Audio source set successfully");
        
        await _audioPlayer.play();
        print("Playback started");
        
        // Monitor playback state
        _audioPlayer.playerStateStream.listen((state) {
          print("Player state: ${state.processingState}");
        });

        // Monitor playback errors
        _audioPlayer.positionStream.listen(
          (position) => print("Playback position: $position"),
          onError: (error) => print("Playback error: $error"),
        );

        // Add duration monitoring
        _audioPlayer.durationStream.listen(
          (duration) => print("Track duration: $duration"),
          onError: (error) => print("Duration error: $error"),
        );
        
      } catch (e) {
        print("Error setting audio source: $e");
        rethrow;
      }
      
      setState(() {
        status = 'Playing audio with pitch $pitch';
      });
    } catch (e, stackTrace) {
      print("Error in playAudioWithPitch: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        status = 'Error playing audio: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('SoundTouch Demo'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => playAudioWithPitch(8.0), // G# pitch
                child: const Text('Play G#'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => playAudioWithPitch(11.0), // B pitch
                child: const Text('Play B'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => playAudioWithPitch(2.0), // 2 semitones pitch
                child: const Text('Play 2 Semitones Up'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: processSound,
                child: const Text('Process Audio'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Create a simple beep using AudioSource.uri
                    await _audioPlayer.setVolume(1.0);
                    await _audioPlayer.setUrl('asset:///assets/audio/test_mono.wav');
                    await _audioPlayer.play();
                    setState(() {
                      status = 'Playing original audio';
                    });
                  } catch (e) {
                    print("Error playing test audio: $e");
                    setState(() {
                      status = 'Error playing test audio: $e';
                    });
                  }
                },
                child: const Text('Play Original'),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _audioPlayer.volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _audioPlayer.setVolume(value);
                  });
                },
                label: 'Volume',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AudioProcessingPage extends StatefulWidget {
  const AudioProcessingPage({super.key});

  @override
  State<AudioProcessingPage> createState() => _AudioProcessingPageState();
}

class _AudioProcessingPageState extends State<AudioProcessingPage> {
  late SoundTouchProcessor _processor;
  int? _handle;  // Add this line
  double _pitch = 0.0;
  double _tempo = 1.0;
  double _rate = 1.0;

  @override
  void initState() {
    super.initState();
    _processor = SoundTouchProcessor();
    _handle = _processor.createSoundTouch();  // Initialize the handle
  }

  @override
  void dispose() {
    if (_handle != null) {
      _processor.disposeSoundTouch(_handle!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Processing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pitch (semitones): ${_pitch.toStringAsFixed(1)}'),
            Slider(
              value: _pitch,
              min: -12.0,
              max: 12.0,
              onChanged: (value) {
                setState(() {
                  _pitch = value;
                  if (_handle != null) {
                    _processor.setPitch(_handle!, _pitch);
                  }
                });
              },
            ),
            Text('Tempo: ${_tempo.toStringAsFixed(1)}x'),
            Slider(
              value: _tempo,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _tempo = value;
                  if (_handle != null) {
                    _processor.setTempo(_handle!, _tempo);
                  }
                });
              },
            ),
            Text('Rate: ${_rate.toStringAsFixed(1)}x'),
            Slider(
              value: _rate,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _rate = value;
                  if (_handle != null) {
                    _processor.setRate(_handle!, _rate);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
