import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'edit_scan_pdf.dart';

class ScanPDFScreen extends StatefulWidget {
  const ScanPDFScreen({super.key});

  @override
  State<ScanPDFScreen> createState() => _ScanPDFScreenState();
}

class _ScanPDFScreenState extends State<ScanPDFScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  String _selectedMode = 'Book'; // Default scan mode
  final List<String> _scanModes = ['Book', 'ID Card', 'Document', 'Receipt'];
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
      Navigator.pop(context);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No cameras available')));
      Navigator.pop(context);
      return;
    }

    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenSize = MediaQuery.of(context).size;
    final overlayMargin = 40.0; // Margin for the overlay
    final overlayWidth = screenSize.width - 2 * overlayMargin;
    final overlayHeight = screenSize.height * 0.6; // Adjust height as needed
    final overlayTop = (screenSize.height - overlayHeight) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(child: CameraPreview(_controller!)),
          // Document overlay with dashed vertical line
          Positioned(
            left: overlayMargin,
            top: overlayTop,
            child: Container(
              width: overlayWidth,
              height: overlayHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: CustomPaint(
                painter: DashedLinePainter(),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        if (_isFlashOn) {
                          await _controller!.setFlashMode(FlashMode.off);
                        } else {
                          await _controller!.setFlashMode(FlashMode.torch);
                        }
                        setState(() => _isFlashOn = !_isFlashOn);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        // Placeholder for settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings not implemented'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Scan modes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        _scanModes.map((mode) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ChoiceChip(
                              label: Text(mode),
                              selected: _selectedMode == mode,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _selectedMode = mode);
                              },
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(
                                color:
                                    _selectedMode == mode
                                        ? Colors.white
                                        : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // Shutter button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo, color: Colors.white),
                      onPressed: () {
                        // Placeholder for gallery picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gallery picker not implemented'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera,
                          size: 60,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final XFile image = await _controller!.takePicture();
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditScanPage(
                                      imagePath: image.path,
                                      isBookMode: _selectedMode == 'Book',
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.document_scanner,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Placeholder for additional options
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Additional options not implemented'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the dashed vertical line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    const dashHeight = 10.0;
    const dashSpace = 5.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
