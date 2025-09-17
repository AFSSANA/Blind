import 'dart:async';
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0D1B2A),
        primaryColor: Colors.indigo,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: Size(double.infinity, 60),
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
    Future.delayed(Duration(seconds: 1), () {
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility,
              size: 100,
              color: Colors.indigoAccent,
            ),
            SizedBox(height: 24),

            Text(
              "BLIND NAV",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 48),

            ElevatedButton(
              onPressed: getLocationAndSpeak,
              child: Text("Speak Current Location"),
            ),
            SizedBox(height: 24),

            ElevatedButton(
              onPressed: isAutoUpdating ? stopAutoUpdate : startAutoUpdate,
              child: Text(isAutoUpdating ? "Stop Auto Updates" : "Start Auto Updates"),
            ),
            SizedBox(height: 24),

            Text(
              isAutoUpdating ? "Auto updates are ON" : "Auto updates are OFF",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 48),

            Text(
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