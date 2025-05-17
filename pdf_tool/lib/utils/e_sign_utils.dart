import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ESignUtils {
  final Logger log = Logger();
  final SignatureController controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  Future<PdfDocument> loadPdfDocument(String pdfPath) async {
    final pdfFile = File(pdfPath);
    return PdfDocument(inputBytes: await pdfFile.readAsBytes());
  }

  Future<void> uploadSignature({
    required Function(Uint8List) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        onSuccess(bytes);
      }
    } catch (err) {
      log.e('Error uploading signature: $err');
      onError('Error Uploading Signature: $err');
    }
  }

  Future<void> signPdf({
    required Uint8List? signatureImage,
    required String pdfPath,
    required Offset signaturePosition,
    required double signatureWidth,
    required double signatureHeight,
    required int currentPage,
    required double screenWidth,
    required double screenHeight,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      if (signatureImage == null) {
        onError('No Signature Provided');
        return;
      }
      final document = await loadPdfDocument(pdfPath);

      if (currentPage < 1 || currentPage > document.pages.count) {
        onError("Invalid page number");
        return;
      }

      final page = document.pages[currentPage - 1];
      final pdfPageWidth = page.getClientSize().width;
      final pdfPageHeight = page.getClientSize().height;

      final pdfAspectRatio = pdfPageWidth / pdfPageHeight;
      final screenAspectRatio = screenWidth / screenHeight;

      double scaleFactor;
      double offsetX = 0;
      double offsetY = 0;

      if (pdfAspectRatio > screenAspectRatio) {
        scaleFactor = pdfPageWidth / screenWidth;
        final displayHeight = screenWidth / pdfAspectRatio;
        offsetY = (screenHeight - displayHeight) / 2;
      } else {
        scaleFactor = pdfPageHeight / screenHeight;
        final displayedWidth = screenHeight * pdfAspectRatio;
        offsetX = (screenWidth - displayedWidth) / 2;
      }

      final pdfX = (signaturePosition.dx - offsetX) * scaleFactor;
      final pdfY = (signaturePosition.dy - offsetY) * scaleFactor;
      final pdfWidth = signatureWidth * scaleFactor;
      final pdfHeight = signatureHeight * scaleFactor;

      log.i(
        'Screen position: ${signaturePosition.dx}, ${signaturePosition.dy}',
      );
      log.i('PDF position: $pdfX, $pdfY');
      log.i('PDF page size: $pdfPageWidth x $pdfPageHeight');
      log.i('Scaled size: $pdfWidth x $pdfHeight');

      final finalX = pdfX.clamp(0, pdfPageWidth - pdfWidth);
      final finalY = pdfY.clamp(0, pdfPageHeight - pdfHeight);

      final PdfBitmap signatureBitmap = PdfBitmap(signatureImage);
      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          finalX.toDouble(),
          finalY.toDouble(),
          pdfWidth,
          pdfHeight,
        ),
      );
      final directory = await getApplicationSupportDirectory();
      final signedPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signedFile = File(signedPath);
      await signedFile.writeAsBytes(await document.save());
      document.dispose();

      onSuccess(signedPath);
    } catch (err) {
      log.e('Error signing PDF: $err');
      onError('Error signing PDF: $err');
    }
  }

  void dispose() {
    controller.dispose();
  }
}
