import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_colors.dart';
import '../utils/image_utils.dart';
import '../widgets/submit_button.dart';
import 'recognize_screen.dart';

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
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Card(
          //   elevation: 2,
          //   shape: BeveledRectangleBorder(
          //     borderRadius: BorderRadius.circular(2),
          //   ),
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     height: MediaQuery.of(context).size.height * 0.6,
          //     width: double.infinity,
          //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          //     child:
          //         (_controller != null && _initializeControllerFuture != null)
          //             ? FutureBuilder(
          //               future: _initializeControllerFuture,
          //               builder: (context, snapshot) {
          //                 if (snapshot.connectionState ==
          //                     ConnectionState.done) {
          //                   return CameraPreview(_controller!);
          //                 } else if (snapshot.hasError) {
          //                   return Center(
          //                     child: Text("Camera Error: ${snapshot.error}"),
          //                   );
          //                 } else {
          //                   return const Center(
          //                     child: CircularProgressIndicator(),
          //                   );
          //                 }
          //               },
          //             )
          //             : const Center(child: CircularProgressIndicator()),
          //   ),
          // ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            // width: MediaQuery.of(context).size.width,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            color: TColor.primary,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Column(
                    children: [
                      Icon(Icons.scanner, color: TColor.white),
                      Text('Scan', style: TextStyle(color: TColor.white)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    XFile? xfile = await imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (xfile != null) {
                      File image = File(xfile.path);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecognizeScreen(image: image),
                        ),
                      );
                    }
                  },
                  icon: Column(
                    children: [
                      Icon(Icons.document_scanner, color: TColor.white),
                      Text('Recognize', style: TextStyle(color: TColor.white)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Column(
                    children: [
                      Icon(Icons.edit_document, color: TColor.white),
                      Text('Enhance', style: TextStyle(color: TColor.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.black,
            child: Container(height: MediaQuery.of(context).size.height - 350),
          ),
          SubmitButton(
            title: 'Scan Document',
            onPressed: () async {
              try {
                if (_controller != null &&
                    _initializeControllerFuture != null) {
                  await _initializeControllerFuture;
                  final image = await _controller!.takePicture();
                  final enhanced = await ImageUtils.enhanceDocumentImage(image);
                  final pdfPath = await ImageUtils.saveAsPdf(enhanced);

                  log('pdfPath: $pdfPath');

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Scanned document saved to $pdfPath"),
                    ),
                  );
                }
              } catch (err) {
                log("Error taking picture: $err");
              }
            },
          ),
        ],
      ),
    );
  }
}
