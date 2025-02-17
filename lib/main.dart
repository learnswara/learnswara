import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'soundtouch/soundtouch_processor.dart';
import 'package:just_audio/just_audio.dart';

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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    // Load the audio file when the app starts
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setAsset('assets/audio/base_ultra_small.wav');
      setState(() {
        status = 'Audio loaded and ready to play';
      });
    } catch (e) {
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
                onPressed: playAudio,
                child: Text(_audioPlayer.playing ? 'Pause Audio' : 'Play Audio'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: processSound,
                child: const Text('Process Audio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> playAudio() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {
          status = 'Audio paused';
        });
      } else {
        await _audioPlayer.play();
        setState(() {
          status = 'Playing audio';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error playing audio: $e';
      });
    }
  }
}

class AudioProcessingPage extends StatefulWidget {
  const AudioProcessingPage({super.key});

  @override
  State<AudioProcessingPage> createState() => _AudioProcessingPageState();
}

class _AudioProcessingPageState extends State<AudioProcessingPage> {
  late SoundTouchProcessor _processor;
  double _pitch = 0.0;
  double _tempo = 1.0;
  double _rate = 1.0;

  @override
  void initState() {
    super.initState();
    _processor = SoundTouchProcessor();
  }

  @override
  void dispose() {
    _processor.dispose();
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
                  _processor.setPitch(_pitch);
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
                  _processor.setTempo(_tempo);
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
                  _processor.setRate(_rate);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
