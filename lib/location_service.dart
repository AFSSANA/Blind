import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart'; // Needed for HapticFeedback

class LocationService {
  final FlutterTts flutterTts;
  Timer? locationTimer;
  // A callback function to tell the UI when the auto-update state changes
  final ValueChanged<bool> onAutoUpdateChanged;

  LocationService({required this.flutterTts, required this.onAutoUpdateChanged});

  Future<void> speak(String message) async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.1);
    await flutterTts.setVolume(1.0);
    await flutterTts.speak(message);
  }

  // 📢 Function exposed for the Volume Down button (or other triggers)
  Future<void> getLocationAndSpeak() async {
    try {
      // 📢 Haptic feedback for command confirmation
      HapticFeedback.lightImpact(); 

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        speak("Location services are disabled. Please enable GPS.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          speak("Location permission denied.");
          return;
        }
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
    // Call the callback to update the UI in main.dart
    onAutoUpdateChanged(true);
  }

  void stopAutoUpdate() {
    speak("Auto location updates stopped.");
    locationTimer?.cancel();
    // Call the callback to update the UI in main.dart
    onAutoUpdateChanged(false);
  }
  
  // 📢 NEW: Function to toggle Auto Updates, exposed for Double-Tap gesture
  void toggleAutoUpdates(bool isCurrentlyUpdating) {
    if (isCurrentlyUpdating) {
      stopAutoUpdate();
    } else {
      startAutoUpdate();
    }
    // 📢 Haptic feedback for toggle action
    HapticFeedback.selectionClick(); 
  }
  
  // 📢 NEW: Placeholder for advanced haptics (Off-course/Arrival)
  void onArrivalAtDestination() {
    // This function will be called once navigation logic is added.
    speak("You have arrived at your destination.");
    // A strong, distinct buzz for arrival
    HapticFeedback.heavyImpact(); 
  }

  void dispose() {
    locationTimer?.cancel();
  }
}