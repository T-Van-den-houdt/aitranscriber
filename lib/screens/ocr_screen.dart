import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemma_service.dart';
import '../services/ocr_service.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});
  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final _ocr = OcrService();
  final _gemma = GemmaService();
  final _picker = ImagePicker();
  
  CameraController? _controller;
  File? _selectedImage;
  String _displayText = "Ready to scan...";
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    if (cams.isEmpty) return;
    
    _controller = CameraController(cams.first, ResolutionPreset.max, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _isBusy = true;
      _displayText = "Extracting text...";
    });

    try {
      final lines = await _ocr.scanFile(path);
      
      for (var line in lines) {
        debugPrint(line.toString());
      }

      if (lines.isEmpty) {
        setState(() => _displayText = "No text found.");
        return;
      }

      setState(() => _displayText = "Gemma is analizing...");

      final stream = _gemma.toJsonStream(lines);
      
      await for (final partialJson in stream) {
        setState(() {
          _displayText = partialJson;
        });
      }
    } catch (e) {
      setState(() => _displayText = "Something went wrong: $e");
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _captureFromCamera() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;
    
    final img = await _controller!.takePicture();
    setState(() => _selectedImage = File(img.path));
    await _processImage(img.path);
  }

  Future<void> _pickFromGallery() async {
    if (_isBusy) return;
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _displayText = "Loading image...";
      });
      await _processImage(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SCANNER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedImage != null) 
            IconButton(
              icon: const Icon(Icons.refresh), 
              onPressed: () => setState(() => _selectedImage = null),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white12),
              ),
              child: _selectedImage != null 
                  ? Image.file(_selectedImage!, fit: BoxFit.contain)
                  : (_controller != null && _controller!.value.isInitialized)
                      ? CameraPreview(_controller!)
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("OUTPUT", style: TextStyle(color: Colors.blueGrey[300], fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                      const Spacer(),
                      if (_isBusy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _displayText,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Actie Knoppen
                  Row(
                    children: [
                      // Gallery Knop
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _pickFromGallery,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.blueAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text("GALLERY"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Scan Knop
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isBusy ? null : _captureFromCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_isBusy ? "BEZIG..." : "SCAN NU"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}