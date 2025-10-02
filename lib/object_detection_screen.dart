import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // 📢 NEW: Import for HapticFeedback

class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ObjectDetectionScreen({super.key, required this.cameras});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _cameraController;
  late ImageLabeler _imageLabeler;
  bool isCameraReady = false;
  String result = "Tap the button to detect objects";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeMLKit();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {
      isCameraReady = true;
    });
  }

  void _initializeMLKit() {
    // Note: The default ML Kit model is generic. For better obstacle detection,
    // a custom model (like a TensorFlow model for coco objects) would be better.
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _processImage() async {
    try {
      // 1. Take Picture
      final XFile picture = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      
      // 2. Process Image
      final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);

      // 3. Check for Detection and Trigger Haptics
      if (labels.isNotEmpty) {
        // 📢 NEW: If any object is detected, trigger a vibration alert.
        // HapticFeedback.vibrate() is a general, strong vibration.
        HapticFeedback.vibrate();
      }

      // 4. Format Results for UI
      String detectedObjects = labels.isNotEmpty
          ? labels.map((label) {
                final labelText = label.label ?? "Unknown";
                final confidence = (label.confidence * 100).toStringAsFixed(2);
                return "$labelText - $confidence%";
              }).join("\n")
          : "No object detected";

      setState(() {
        result = detectedObjects;
      });
    } catch (e) {
      print("Error processing image: $e");
      setState(() {
        result = "Error detecting objects";
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff213555),
        title: const Text("Object Detection", style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xff3E5879),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: isCameraReady
                  ? CameraPreview(_cameraController)
                  : const CircularProgressIndicator(),
            ),
          ),
          Container(
            width: mq.size.width,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0x5af0bb78),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Detected Objects",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Text(
                    result,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _processImage,
                  child: const Text("Detect Objects"),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Warning: App vibrates if an object is detected.", 
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}