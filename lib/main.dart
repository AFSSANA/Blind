import 'dart:async'; // ✅ Added for Timer
import 'package:geocoding/geocoding.dart';
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
  Timer? locationTimer;
  bool isAutoUpdating = false;

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

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String locationText =
            "You are near ${place.street}, ${place.locality}, ${place.administrativeArea}";
        print("Reverse geocoded location: $locationText");
        speak(locationText);
      } else {
        speak("Location found, but address details are unavailable.");
      }
    } catch (e) {
      print("Location error: $e");
      speak("Failed to get location. Please check your settings.");
    }
  }

  void startAutoUpdate() {
    speak("Auto location updates started.");
    locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
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
      appBar: AppBar(title: Text("Blind Nav")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getLocationAndSpeak,
              child: Text("Speak Current Location"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAutoUpdating ? stopAutoUpdate : startAutoUpdate,
              child: Text(isAutoUpdating ? "Stop Auto Updates" : "Start Auto Updates"),
            ),
          ],
        ),
      ),
    );
  }
}