import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

class PdfUtil {
  static Future<Uint8List> mergePDFs(List<String> pdfPaths) async {
    final PdfDocument outputDocument = PdfDocument();

    for (String path in pdfPaths) {
      final PdfDocument inputDoc = PdfDocument(
        inputBytes: File(path).readAsBytesSync(),
      );

      // Import each page properly
      outputDocument.pages.add().graphics.drawPdfTemplate(
        inputDoc.pages[0].createTemplate(),
        const Offset(0, 0),
      );

      for (int i = 1; i < inputDoc.pages.count; i++) {
        final page = outputDocument.pages.add();
        page.graphics.drawPdfTemplate(
          inputDoc.pages[i].createTemplate(),
          const Offset(0, 0),
        );
      }

      inputDoc.dispose();
    }

    final List<int> bytes = await outputDocument.save();
    outputDocument.dispose();

    return Uint8List.fromList(bytes);
  }

  static Future<List<Uint8List>> splitPdf(
    String pdfPath,
    String pagesInput,
  ) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await File(pdfPath).readAsBytes(),
    );

    final int totalPages = document.pages.count;

    // Parse the pages input (eg, "1,3-5,7")
    final List<List<int>> pageGroups = [];
    for (String part in pagesInput.split(",")) {
      if (part.contains('-')) {
        final List<int> range = part.split('-').map(int.parse).toList();
        if (range[0] < 1 || range[1] > totalPages || range[0] > range[1]) {
          throw Exception('Invalid range: $part');
        }
        pageGroups.add(
          List.generate(range[1] - range[0] + 1, (i) => range[0] + i),
        );
      } else {
        final int pageNum = int.parse(part);
        if (pageNum < 1 || pageNum > totalPages) {
          throw Exception('Invalid page: $pageNum');
        }
        pageGroups.add([pageNum]);
      }
    }

    // Create a new pdf for each group
    final List<Uint8List> outputFiles = [];
    for (List<int> pageList in pageGroups) {
      final PdfDocument newDocument = PdfDocument();
      for (int pageNum in pageList) {
        newDocument.pages.add();
        final PdfTemplate template =
            document.pages[pageNum - 1].createTemplate();
        newDocument.pages[newDocument.pages.count - 1].graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
        );
      }
      final Uint8List bytes = Uint8List.fromList(await newDocument.save());
      newDocument.dispose();
      outputFiles.add(bytes);
    }

    document.dispose();
    return outputFiles;
  }

  // static Future<String> convertPDFToWord(String pdfPath) async {
  //   //Load the pdf
  //   final PdfDocument document = PdfDocument(
  //     inputBytes: await File(pdfPath).readAsBytes(),
  //   );

  //   // Extract text from all pages
  //   final StringBuffer textBuffer = StringBuffer();
  //   for (int i = 0; i < document.pages.count; i++) {
  //     final String pageText = PdfTextExtractor(
  //       document,
  //     ).extractText(startPageIndex: i);
  //     textBuffer.writeln(pageText);
  //   }

  //   document.dispose();

  //   // Create a Word Document
  //   final doc = docx.Document();
  //   doc.addParagraph(docx.Paragraph.wthText(textBuffer.toString()));

  //   // save the .docx file
  //   final List<int> docxBytes = await doc.save();
  //   final Directory directory = await getApplicationCacheDirectory();
  //   final String docxPath = '${directory.path}/converted.docx';
  //   final File docxFile = File(docxPath);
  //   await docxFile.writeAsBytes(docxBytes, flush: true);

  //   return docxPath;
  // }

  // Convert an image to PDF
  static Future<String> imageToPdf(String imagePath) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final img.Image? image = img.decodeImage(
      await File(imagePath).readAsBytes(),
    );
    if (image == null) {
      throw Exception('Falied to decode image for PDF Conversion');
    }

    // convert image to bytes for PDF
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

    // save the pdf
    final Directory directory = await getApplicationSupportDirectory();
    final String pdfPath = '${directory.path}/scanned_document.pdf';
    await File(pdfPath).writeAsBytes(await document.save());
    document.dispose();
    return pdfPath;
  }
}
