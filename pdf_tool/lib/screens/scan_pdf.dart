import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/image_utils.dart';

class ScanPDFScreen extends ConsumerStatefulWidget {
  const ScanPDFScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ScanPDFScreenState();
}

class _ScanPDFScreenState extends ConsumerState<ScanPDFScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late ImagePicker imagePicker;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    imagePicker = ImagePicker();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _controller = CameraController(backCamera, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();

      // Wait for camera to be initialized before rebuilding
      await _initializeControllerFuture;

      if (mounted) setState(() {});
    } catch (e) {
      log("Camera init failed: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> scanAndSaveDocument(BuildContext context) async {
    final file = await ImageUtils.pickDocumentImage();
    if (file != null) {
      final enhanced = await ImageUtils.enhanceDocumentImage(file);
      final pdfPath = await ImageUtils.saveAsPdf(enhanced);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Document saved to $pdfPath")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          (_controller != null && _initializeControllerFuture != null)
              ? FutureBuilder(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!);
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text("Camera Error: ${snapshot.error}"),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              )
              : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            if (_controller != null && _initializeControllerFuture != null) {
              await _initializeControllerFuture;
              final image = await _controller!.takePicture();
              final enhanced = await ImageUtils.enhanceDocumentImage(image);
              final pdfPath = await ImageUtils.saveAsPdf(enhanced);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Scanned document saved to $pdfPath")),
              );
            }
          } catch (err) {
            log("Error taking picture: $err");
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
