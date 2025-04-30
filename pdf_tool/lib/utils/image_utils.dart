import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
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
  static Future<String> imageToPdf(String imagePath) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final img.Image? image = img.decodeImage(
      await File(imagePath).readAsBytes(),
    );
    if (image == null) {
      throw Exception('Failed to decode image for PDF conversion');
    }

    // Convert image to bytes for PDF
    final Uint8List imageBytes = Uint8List.fromList(img.encodeJpg(image));
    final PdfBitmap pdfImage = PdfBitmap(imageBytes);
    page.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(
        0,
        0,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );

    // Save the PDF
    final Directory directory = await getApplicationSupportDirectory();
    final String pdfPath = '${directory.path}/scanned_document.pdf';
    await File(pdfPath).writeAsBytes(await document.save());
    document.dispose();
    return pdfPath;
  }
}
