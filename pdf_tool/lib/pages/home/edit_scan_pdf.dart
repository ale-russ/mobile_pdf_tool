import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../providers/action_history_provider.dart';
import '../../utils/helper_methods.dart';
import '../../utils/image_utils.dart';
import '../../utils/pdf_util.dart';
import '../../providers/pdf_state_provider.dart';

class EditScanPage extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isBookMode;

  const EditScanPage({
    super.key,
    required this.imagePath,
    this.isBookMode = false,
  });

  @override
  ConsumerState<EditScanPage> createState() => _EditScanPageState();
}

class _EditScanPageState extends ConsumerState<EditScanPage> {
  List<String> _currentImagePaths = [];
  List<String> _scannedImages = [];
  double _rotationAngle = 0;
  bool _isAutoEnhanced = false;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  Future<void> _initializeImages() async {
    if (widget.isBookMode) {
      // Split the image into two pages
      final img.Image? image = img.decodeImage(
        await File(widget.imagePath).readAsBytes(),
      );
      if (image == null) return;

      final int halfWidth = image.width ~/ 2;
      final img.Image leftPage = img.copyCrop(
        image,
        x: 0,
        y: 0,
        width: halfWidth,
        height: image.height,
      );
      final img.Image rightPage = img.copyCrop(
        image,
        x: halfWidth,
        y: 0,
        width: halfWidth,
        height: image.height,
      );

      final Directory directory = await getApplicationSupportDirectory();
      final String leftPath = '${directory.path}/left_page.jpg';
      final String rightPath = '${directory.path}/right_page.jpg';

      await File(leftPath).writeAsBytes(img.encodeJpg(leftPage));
      await File(rightPath).writeAsBytes(img.encodeJpg(rightPage));

      _currentImagePaths = [leftPath, rightPath];
      _scannedImages.addAll([leftPath, rightPath]);
    } else {
      _currentImagePaths = [widget.imagePath];
      _scannedImages = [widget.imagePath];
    }
    setState(() {});
  }

  Future<void> _applyAutoEnhance() async {
    setState(() => _isAutoEnhanced = true);
    final List<String> enhancedPaths = [];
    for (final path in _currentImagePaths) {
      final enhancedPath = await ImageUtils.enhanceImage(path);
      enhancedPaths.add(enhancedPath);
    }
    _currentImagePaths = enhancedPaths;
    setState(() {});
  }

  Future<void> _rotateImages() async {
    final List<String> rotatedPaths = [];
    for (final path in _currentImagePaths) {
      final img.Image? image = img.decodeImage(await File(path).readAsBytes());
      if (image == null) continue;

      _rotationAngle += 90;
      if (_rotationAngle >= 360) _rotationAngle = 0;
      final rotatedImage = img.copyRotate(image, angle: 90);

      final Directory directory = await getApplicationSupportDirectory();
      final String rotatedPath =
          '${directory.path}/rotated_${path.split('/').last}';
      await File(rotatedPath).writeAsBytes(img.encodeJpg(rotatedImage));
      rotatedPaths.add(rotatedPath);
    }
    _currentImagePaths = rotatedPaths;
    setState(() {});
  }

  Future<void> _applyFilter() async {
    final List<String> filteredPaths = [];
    for (final path in _currentImagePaths) {
      final img.Image? image = img.decodeImage(await File(path).readAsBytes());
      if (image == null) continue;

      final filteredImage = img.grayscale(image);
      final Directory directory = await getApplicationSupportDirectory();
      final String filteredPath =
          '${directory.path}/filtered_${path.split('/').last}';
      await File(filteredPath).writeAsBytes(img.encodeJpg(filteredImage));
      filteredPaths.add(filteredPath);
    }
    _currentImagePaths = filteredPaths;
    setState(() {});
  }

  Future<void> _retake() async {
    Navigator.pop(context); // Return to scanning page to retake
  }

  Future<void> _saveAsPdf() async {
    try {
      final List<String> pdfPaths = [];
      for (final imagePath in _scannedImages) {
        final String enhancedPath =
            _isAutoEnhanced
                ? await ImageUtils.enhanceImage(imagePath)
                : imagePath;
        final String pdfPath = await PdfUtil.imageToPdf(enhancedPath);
        pdfPaths.add(pdfPath);
      }

      // Merge PDFs if multiple pages
      final String finalPdfPath =
          pdfPaths.length > 1
              ? await HelperMethods.saveFile(
                await PdfUtil.mergePDFs(pdfPaths),
                'scanned_document.pdf',
              )
              : pdfPaths.first;

      // Update the state in PdfEditorScreen
      ref.read(pdfStateProvider.notifier).setPdfPath([finalPdfPath]);
      ref.read(pdfStateProvider.notifier).state = ref
          .read(pdfStateProvider)
          .copyWith(selectedPdfs: [finalPdfPath]);
      ref.read(actionHistoryProvider.notifier).addAction('Scanned Document');

      // Navigate back to PdfEditorScreen
      Navigator.popUntil(context, (route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document scanned and saved as PDF')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Scan')),
      body: Column(
        children: [
          Expanded(
            child:
                _currentImagePaths.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : widget.isBookMode
                    ? Row(
                      children: [
                        Expanded(
                          child: Image.file(File(_currentImagePaths[0])),
                        ),
                        Expanded(
                          child: Image.file(File(_currentImagePaths[1])),
                        ),
                      ],
                    )
                    : Image.file(File(_currentImagePaths[0])),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                onPressed: _applyAutoEnhance,
                tooltip: 'Auto',
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _retake,
                tooltip: 'Retake',
              ),
              IconButton(
                icon: const Icon(Icons.crop),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Crop feature not implemented'),
                    ),
                  );
                },
                tooltip: 'Crop',
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right),
                onPressed: _rotateImages,
                tooltip: 'Rotate',
              ),
              IconButton(
                icon: const Icon(Icons.filter),
                onPressed: _applyFilter,
                tooltip: 'Filter',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  ); // Go back to scanning page to scan more
                },
                child: const Text('Scan More'),
              ),
              ElevatedButton(
                onPressed: _saveAsPdf,
                child: const Text('Save PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
