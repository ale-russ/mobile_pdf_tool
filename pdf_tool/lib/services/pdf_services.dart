import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PdfServices {
  var baseUrl = "http://10.0.2.2:5000";
  var dio = Dio();
  Future<File> mergePdfs(List<String> filePaths) async {
    var formData = FormData();

    for (var path in filePaths) {
      formData.files.add(MapEntry("files", await MultipartFile.fromFile(path)));
    }
    try {
      final response = await dio.post(
        "$baseUrl/merge",
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );
      final tempDir = await getTemporaryDirectory();
      final mergedFile = File("${tempDir.path}/merged.pdf");
      await mergedFile.writeAsBytes(response.data);
      return mergedFile;
    } catch (err) {
      log('Error: $err');
      throw Exception('Internal Server Error');
    }
  }

  Future<void> connectToServer() async {
    try {
      var response = await dio.get('$baseUrl/docs');
      log('response: ${response.data}');
    } catch (err) {
      throw Exception('Error: $err');
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
