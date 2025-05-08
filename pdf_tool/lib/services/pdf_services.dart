import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class PdfServices {
  var baseUrl = "http://10.0.2.2:5000";
  var dio = Dio();
  final formData = FormData();

  Future<File> saveTempFile(Response<dynamic> response, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final resultFile = File("${tempDir.path}/$fileName.pdf");
    await resultFile.writeAsBytes(response.data);
    return resultFile;
  }

  Future<void> connectToServer() async {
    try {
      var response = await dio.get('$baseUrl/docs');
      log('response: ${response.data}');
    } catch (err) {
      throw Exception('Error: $err');
    }
  }

  Future<File> mergePdfs(List<String> filePaths) async {
    for (var path in filePaths) {
      formData.files.add(MapEntry("files", await MultipartFile.fromFile(path)));
    }
    try {
      final response = await dio.post(
        "$baseUrl/merge",
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );
      return await saveTempFile(response, "mergedFile");
    } catch (err) {
      log('Error: $err');
      throw Exception('Internal Server Error');
    }
  }

  Future<File> splitPdfs(String filePath, String pageRanges) async {
    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: 'split.pdf'),
      "pages": pageRanges,
    });

    try {
      final response = await dio.post(
        "$baseUrl/split",
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );
      return await saveTempFile(response, "splittedFile");
    } catch (err) {
      log("Error: $err");
      throw Exception('Internal Server Error');
    }
  }

  Future<File> convertImageToPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result == null) throw Exception('No File Selected');

    for (int i = 0; i < result.files.length; i++) {
      final file = result.files[i];
      CroppedFile? croppedImage;
      final mimeType = lookupMimeType(file.path!);
      log('mimeType: $mimeType');
      final contentType =
          mimeType != null
              ? MediaType.parse(mimeType)
              : MediaType('application', 'octet-stream');
      // croppedImage = await ImageCropper.platform.cropImage(
      //   sourcePath: file.path!,
      // );
      croppedImage = await ImageCropper().cropImage(
        sourcePath: file.path!,
        // aspectRatio: CropAspectRatioPreset.square as CropAspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );
      if (croppedImage != null) {
        formData.files.add(
          MapEntry(
            "files",
            await MultipartFile.fromFile(
              // file.path!,
              croppedImage.path,
              filename: file.name,
              contentType: contentType,
            ),
          ),
        );
      }
    }

    try {
      final response = await dio.post(
        '$baseUrl/image-to-pdf',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      final savedFile = await saveTempFile(response, 'image');
      log('savedFile: $savedFile');
      return savedFile;
    } catch (err) {
      log('Error: $err');
      throw Exception('Internal Server Error');
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

  Future<String?> extractTextFromImage(File file) async {
    try {
      final mimeType = lookupMimeType(file.path);
      final contentType =
          mimeType != null
              ? MediaType.parse(mimeType)
              : MediaType('application', 'octet-stream');

      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(file.path, contentType: contentType),
        ),
      );

      final response = await dio.post(
        "$baseUrl/extract-text-from-image",
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final text = data['text'] as String;
        return text;
      }
      return null;
    } catch (err) {
      log('Error: $err');
      rethrow;
    }
  }
}
