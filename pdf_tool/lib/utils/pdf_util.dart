import 'dart:io';
import 'dart:typed_data';
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
