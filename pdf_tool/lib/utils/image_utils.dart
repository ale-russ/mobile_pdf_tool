import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImageUtils {
  static Future<XFile?> pickDocumentImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.camera);
  }

  static Future<String> enhanceImage(String imagePath) async {
    // Read the image
    final img.Image? image = img.decodeImage(
      await File(imagePath).readAsBytes(),
    );
    if (image == null) throw Exception('Failed to decode image');

    // Adjust brightness and contrast
    img.Image adjustedImage = img.adjustColor(
      image,
      brightness: 1.2, // Increase brightness by 20%
      contrast: 1.5, // Increase contrast by 50%
    );

    // Despeckle to remove noise (simple median filter approximation)
    adjustedImage = img.noise(adjustedImage, 0.5);

    // Deskew the image (basic implementation using rotation)
    // Note: For more accurate deskew, consider a library with Hough transform
    adjustedImage = img.copyRotate(
      adjustedImage,
      angle: _detectSkew(adjustedImage),
    );

    // Save the enhanced image
    final Directory directory = await getApplicationSupportDirectory();
    final String enhancedPath = '${directory.path}/enhanced_scan.jpg';
    await File(enhancedPath).writeAsBytes(img.encodeJpg(adjustedImage));
    return enhancedPath;
  }

  // Basic skew detection (simplified for demonstration)
  static double _detectSkew(img.Image image) {
    // In a real app, use Hough transform or a library like OpenCV for accurate deskew
    // This is a placeholder returning a small rotation angle
    return 0.5; // Rotate by 0.5 degrees (adjust based on actual detection)
  }

  static Future<String> saveAsPdf(img.Image enhancedImage) async {
    final pdf = pw.Document();
    final imgBytes = img.encodeJpg(enhancedImage);

    final pwImage = pw.MemoryImage(imgBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(child: pw.Image(pwImage)),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/scanned_doc_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // Convert an image to PDF
  static Future<Uint8List> imageToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) throw Exception('Empty File');

    final PdfDocument document = PdfDocument();

    for (final file in result.files) {
      CroppedFile? croppedImage;
      try {
        croppedImage = await ImageCropper.platform.cropImage(
          sourcePath: file.path!,
        );
      } catch (err) {
        debugPrint('Cropping failed for ${file.name} with error: $err');
        throw Exception('Unable to Convert Image to PDF');
      }

      final Uint8List imageBytes = File(croppedImage!.path).readAsBytesSync();

      final PdfPage page = document.pages.add();
      log('page: $page');
      final PdfImage image = PdfBitmap(imageBytes);

      page.graphics.drawImage(
        image,
        Rect.fromLTWH(
          0,
          0,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
      );
    }
    final List<int> bytes = await document.save();

    document.dispose();

    return Uint8List.fromList(bytes);
  }

  static Future<File?> cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: true,
          cropFrameStrokeWidth: 2,
          showCropGrid: true,
          cropGridStrokeWidth: 1,
          activeControlsWidgetColor: Colors.blue,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }
}
