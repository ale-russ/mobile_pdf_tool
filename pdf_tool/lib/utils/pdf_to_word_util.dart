// // lib/features/pdf_tools/convert/pdf_to_word_util.dart
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_filex/open_filex.dart';

// class PdfToWordUtil {
//   static Future<String> convertToWord(String pdfPath) async {
//     final Uint8List pdfBytes = await File(pdfPath).readAsBytes();

//     // Load PDF document
//     final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

//     // Convert to Word
//     final List<int> wordBytes = document.;

//     document.dispose();

//     // Save Word file
//     final Directory dir = await getApplicationDocumentsDirectory();
//     final String outputPath = '${dir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.docx';

//     final File wordFile = File(outputPath);
//     await wordFile.writeAsBytes(wordBytes, flush: true);

//     return wordFile.path;
//   }

//   static Future<void> openWordFile(String path) async {
//     await OpenFilex.open(path);
//   }
// }
