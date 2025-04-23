import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static Future<XFile?> pickDocumentImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.camera);
  }

  static Future<img.Image> enhanceDocumentImage(XFile file) async {
    final bytes = await file.readAsBytes();
    img.Image image = img.decodeImage(bytes)!;

    // Convert to grayscale
    img.grayscale(image);

    // Apply contrast enhancement
    img.adjustColor(image, contrast: 1.2);

    return image;
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
}
