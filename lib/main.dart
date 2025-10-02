import 'dart:async';
import 'dart:math'; 

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Official, Null-Safe Sensor Package

import 'object_detection_screen.dart';
import 'speech_to_text.dart';
import 'location_service.dart'; 

// This list should be populated in the main function as before
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure the app can access the location service and camera
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
  // Service instance for location and TTS logic
  late LocationService _locationService;
  
  bool isAutoUpdating = false;
  final SpeakToTextPage _speechPage = const SpeakToTextPage();
  
  // 📢 FIX: Shake Detection variables using sensors_plus
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  final double shakeThreshold = 15.0; // Sensitivity threshold
  DateTime? _lastShakeTime;
  final Duration shakeDebounceTime = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    // Initialize the Location Service, passing the UI state update function
    _locationService = LocationService(
      flutterTts: FlutterTts(),
      onAutoUpdateChanged: (bool isUpdating) {
        setState(() {
          isAutoUpdating = isUpdating;
        });
      }
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      _locationService.speak("Welcome to Blind Nav. Double tap anywhere to toggle auto updates, or shake the phone for voice command.");
    });
    
    // Initialize hands-free controls
    _initializeShakeSensor(); 
  }
  
  // 📢 FIX: Corrected Shake Detection method using Accelerometer API
  void _initializeShakeSensor() {
    _accelerometerSubscription = accelerometerEventStream(
      // FIX: Use samplingPeriod and a Duration value instead of deprecated named parameters
      samplingPeriod: Duration(milliseconds: 16), // Approx 60Hz (Game speed)
    ).listen(
      (AccelerometerEvent event) {
        // Calculate the magnitude of acceleration vector (force)
        final double magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        
        // Check if the force exceeds the threshold and if the debounce time has passed
        if (magnitude > shakeThreshold) {
          final now = DateTime.now();
          if (_lastShakeTime == null || now.difference(_lastShakeTime!) > shakeDebounceTime) {
            _lastShakeTime = now;
            _handleShakeGesture();
          }
        }
      },
    );
  }

  void _handleShakeGesture() {
    // Only trigger if we are on the main screen
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      HapticFeedback.mediumImpact(); 
      _locationService.speak("Listening for command..."); 
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _speechPage,
        ),
      );
    }
  }

  void _handleDoubleTap() {
    _locationService.toggleAutoUpdates(isAutoUpdating);
  }
  
  @override
  void dispose() {
    _locationService.dispose(); 
    _accelerometerSubscription.cancel(); // Cancel the accelerometer stream
    _locationService.flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Scaffold(
        // FIX: Wrapped content in SingleChildScrollView to fix "BOTTOM OVERFLOWED" error
        body: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, 
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
                // Button 1: Speak Current Location
                ElevatedButton(
                  onPressed: _locationService.getLocationAndSpeak,
                  child: const Text("Speak Current Location"),
                ),
                const SizedBox(height: 24),
                // Button 2: Start/Stop Auto Updates
                ElevatedButton(
                  onPressed: () => _locationService.toggleAutoUpdates(isAutoUpdating),
                  child: Text(isAutoUpdating ? "Stop Auto Updates" : "Start Auto Updates"),
                ),
                const SizedBox(height: 24),
                Text(
                  isAutoUpdating ? "Auto updates are ON" : "Auto updates are OFF",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                // Button 3: Start Object Detection
                ElevatedButton(
                  onPressed: () {
                    // Automatically start Auto Updates when Object Detection is started
                    if (!isAutoUpdating) {
                       _locationService.startAutoUpdate();
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObjectDetectionScreen(cameras: cameras),
                      ),
                    );
                  },
                  child: const Text("Start Object Detection (Auto-Updates Start)"),
                ),
                // The old "Voice Command" button is now implicitly removed, and the overflow is fixed.
                
                const SizedBox(height: 48), 
                const Text(
                  "Hands-Free Controls:", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                // Instructions for users (Cleaned up)
                const Text(
                  "• Shake: Voice Command\n• Double-Tap: Toggle Auto-Updates", 
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Ensure GPS is enabled for accurate location.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}