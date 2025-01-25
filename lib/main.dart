import 'package:flutter/material.dart';
import 'soundtouch/soundtouch_processor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnSwara',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioProcessingPage(),
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
