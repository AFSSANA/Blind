import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(BlindNavApp());

class BlindNavApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Nav',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: VoiceHome(),
    );
  }
}

class VoiceHome extends StatefulWidget {
  @override
  State<VoiceHome> createState() => _VoiceHomeState();
}

class _VoiceHomeState extends State<VoiceHome> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    speak("Welcome to Blind Nav");
  }

  Future<void> speak(String message) async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.1);
    await flutterTts.setVolume(1.0);
    await flutterTts.speak(message);
  }

  Future<void> getLocationAndSpeak() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("Location service enabled: $serviceEnabled");

      if (!serviceEnabled) {
        speak("Location services are disabled. Please enable GPS.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("Initial permission status: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print("Requested permission status: $permission");

        if (permission == LocationPermission.denied) {
          speak("Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        speak("Location permission permanently denied.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      String locationText =
          "Your current location is latitude ${position.latitude.toStringAsFixed(4)}, longitude ${position.longitude.toStringAsFixed(4)}";
      speak(locationText);
    } catch (e) {
      print("Location error: $e");
      speak("Failed to get location. Please check your settings.");
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blind Nav")),
      body: Center(
        child: ElevatedButton(
          onPressed: getLocationAndSpeak,
          child: Text("Speak Current Location"),
        ),
      ),
    );
  }
}