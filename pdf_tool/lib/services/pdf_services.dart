import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:pdf_tool/providers/action_history_provider.dart';
import 'package:pdf_tool/providers/pdf_state_provider.dart';

class PdfServices {
  // var baseUrl = "http://0.0.0.0:8000";
  var baseUrl = "http://10.0.2.2:8000";
  var dio = Dio();
  Future<void> mergePdfs(WidgetRef ref) async {
    var formData = FormData();

    List<String> filePaths = [ref.read(pdfStateProvider).pdfPaths!.first];
    for (var path in filePaths) {
      formData.files.add(MapEntry("files", await MultipartFile.fromFile(path)));
    }
    try {
      await dio.post("backdend_url/merge", data: formData);
      ref.read(actionHistoryProvider.notifier).addAction('Merge PDFs');
    } catch (err) {
      log('Error: $err');
    }
  }

  Future<String> convertPdfToWord(String pdfPath) async {
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(pdfPath),
    });

    try {
      var url = '$baseUrl/convert-to-word';
      var response = await dio.post(url, data: formData);

      if (response.statusCode == 200 && response.data['files'] != null) {
        final String docxPath = response.data['files'][0];
        return docxPath;
      } else {
        return 'Unexpected server response';
      }
    } catch (err) {
      String errorMessage = 'Failed to convert to Word';
      if (err is DioException && err.response != null) {
        errorMessage = err.response?.data['detail'] ?? errorMessage;
      } else {
        errorMessage = 'Error converting to Word: $err';
      }
      return errorMessage;
    }
  }
}
