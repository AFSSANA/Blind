import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'object_detection_screen.dart';
import 'splash_screen.dart';
import 'speech_to_text.dart'; // ✅ Voice command screen

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(BlindNavApp());
}

class BlindNavApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Nav',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        primaryColor: Colors.indigo,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: const Size(double.infinity, 60),
          ),
        ),
      ),
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
  Timer? locationTimer;
  bool isAutoUpdating = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      speak("Welcome to Blind Nav. Tap the button to hear your current location or enable auto updates.");
    });
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
      if (!serviceEnabled) {
        speak("Location services are disabled. Please enable GPS.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationText =
            "You are near ${place.name}, ${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
        speak(locationText);
      } else {
        speak("Location found, but address details are unavailable.");
      }
    } catch (e) {
      speak("Failed to get location. Please check your settings.");
    }
  }

  void startAutoUpdate() {
    speak("Auto location updates started.");
    locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      getLocationAndSpeak();
    });
    setState(() {
      isAutoUpdating = true;
    });
  }

  void stopAutoUpdate() {
    speak("Auto location updates stopped.");
    locationTimer?.cancel();
    setState(() {
      isAutoUpdating = false;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.visibility,
              size: 100,
              color: Colors.indigoAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              "BLIND NAV",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: getLocationAndSpeak,
              child: const Text("Speak Current Location"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isAutoUpdating ? stopAutoUpdate : startAutoUpdate,
              child: Text(isAutoUpdating ? "Stop Auto Updates" : "Start Auto Updates"),
            ),
            const SizedBox(height: 24),
            Text(
              isAutoUpdating ? "Auto updates are ON" : "Auto updates are OFF",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ObjectDetectionScreen(cameras: cameras),
                  ),
                );
              },
              child: const Text("Start Object Detection"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpeakToTextPage(), // ✅ Voice command screen
                  ),
                );
              },
              child: const Text("Voice Command"),
            ),
            const SizedBox(height: 48),
            const Text(
              "Ensure GPS is enabled for accurate location.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}