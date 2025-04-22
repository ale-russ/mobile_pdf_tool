import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

class PdfUtil {
  // Merge multiple PDFs into a single PDF file
  static Future<Uint8List> mergePDFs(List<String> pdfPaths) async {
    final PdfDocument mergedDocument = PdfDocument();

    for (String path in pdfPaths) {
      final PdfDocument loadedDocument = PdfDocument(
        inputBytes: await File(path).readAsBytes(),
      );

      // Import all pages from the loaded document
      for (int i = 0; i < loadedDocument.pages.count; i++) {
        mergedDocument.pages.add();
        final PdfPageTemplateElement template =
            loadedDocument.pages[i].createTemplate() as PdfPageTemplateElement;
        mergedDocument.pages[mergedDocument.pages.count - 1].graphics
            .drawPdfTemplate(template as PdfTemplate, const Offset(0, 0));
      }

      loadedDocument.dispose();
    }

    final Uint8List bytes = Uint8List.fromList(await mergedDocument.save());
    mergedDocument.dispose();
    return bytes;
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
    final img.Image? image = img.decodedImage(
      await File(imagePath).readAsBytes(),
    );
    if (image == null) throw Exception('Falied to decode image for PDF Conversion');

    // convert image to bytes for PDF
    final Uint8List imageBytes = Uint8List.fromList(img.encodeJpg(image));
    final PdfBitmap pdfImage = PdfBitmap(imageBytes);

    page.graphics.drawImage(pdfImage, Rect.fromLTWH(0,0 page.getClientSize().width, page.getClientSize().height));

    // save the pdf
    final Directory directory = await getApplicationSupportDirectory();
    final String pdfPath = '${directory.path}/scanned_document.pdf';
    await File(pdfPath).writeAsBytes(await document.save());
    document.dispose();
    return pdfPath;
  }

  //save a single File
  static Future<String> saveFile(Uint8List bytes, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/$fileName.pdf';
    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  // Save multiple PDF files (for splitting)
  static Future<List<String>> saveMultipleFiles(
    List<Uint8List> fileBytes,
    String baseName,
  ) async {
    final List<String> paths = [];
    for (int i = 0; i < fileBytes.length; i++) {
      final String path = await saveFile(
        fileBytes[i],
        '${baseName}_${i + 1}.pdf',
      );
      paths.add(path);
    }
    return paths;
  }

  // open a file
  static Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}
