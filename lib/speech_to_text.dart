import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const BlindNavApp());
}

class BlindNavApp extends StatelessWidget {
  const BlindNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xff213555),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff213555),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const SpeakToTextPage(),
    );
  }
}

class SpeakToTextPage extends StatefulWidget {
  const SpeakToTextPage({super.key});

  @override
  State<SpeakToTextPage> createState() => _SpeakToTextPageState();
}

class _SpeakToTextPageState extends State<SpeakToTextPage> {
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? _filePath;
  String _transcription = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/recording.m4a';
    await _recorder!.startRecorder(toFile: _filePath, codec: Codec.aacMP4);
    setState(() {
      isRecording = true;
      _transcription = "";
    });
  }

  Future<void> _stopRecording() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false;
    });
    if (_filePath != null) {
      await _sendToWhisper(_filePath!);
    }
  }

  Future<void> _sendToWhisper(String path) async {
    setState(() {
      _isLoading = true;
    });

    String _apiKey = ''; // 🔐 Add your OpenAI API key here

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    )
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..files.add(await http.MultipartFile.fromPath('file', path))
      ..fields['model'] = 'whisper-1';

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
      setState(() {
        _transcription = decoded['text'] ?? "Transcription Error";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _transcription = "Failed to transcribe. Try again.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Assistant"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isRecording)
              LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.green,
                size: 80,
              )
            else
              const SizedBox(height: 40),
            const SizedBox(height: 30),
            Text('Transcription:', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            if (_isLoading)
              LoadingAnimationWidget.threeRotatingDots(color: Colors.blue, size: 60)
            else
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: Text(
                  _transcription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          isRecording ? _stopRecording() : _startRecording();
        },
        tooltip: 'Mic',
        child: Icon(isRecording ? Icons.mic : Icons.mic_off),
      ),
    );
  }
}