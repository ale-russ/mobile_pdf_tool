import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

import '../notifiers/pdf_state_notifier.dart';
import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import 'recent_file_storage.dart';

class HelperMethods {
  static void pickFiles(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      // allowedExtensions: ['pdf'],
    );

    log('Picked files: ${result?.paths}');
    if (result != null && result.files.isNotEmpty) {
      final validPaths =
          result.paths
              .whereType<String>()
              .where((path) => File(path).existsSync())
              .toSet();
      log('Valid paths: $validPaths');
      if (validPaths.isNotEmpty) {
        List<String> paths = result.paths.whereType<String>().toList();
        ref.read(pdfStateProvider.notifier).setPdfPath(paths);
        // ref.read(pdfStateProvider.notifier).state = ref
        //     .read(pdfStateProvider)
        //     .copyWith(selectedPdfs: validPaths);
        ref.read(pdfStateProvider.notifier).updateSelectedPdfs(validPaths);
        final recentFileStorage = RecentFileStorage();
        await recentFileStorage.addFile(validPaths.first);

        ref.read(actionHistoryProvider.notifier).addAction('Imported PDF');
      } else {
        log('No Valid PDF Found');
      }
    }
  }

  static Future<void> filePicker({
    required WidgetRef ref,
    required PdfStateNotifier notifier,
    bool allowMultiple = true,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: allowMultiple,
      // allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final validPaths =
          result.paths
              .whereType<String>()
              .where((path) => File(path).existsSync())
              .toList();

      if (validPaths.isNotEmpty) {
        notifier.setPdfPath(validPaths);
        // notifier.state = notifier.state.copyWith(
        //   selectedPdfs: validPaths.toSet(),
        // );
        notifier.updateSelectedPdfs(validPaths.toSet());

        final recentFileStorage = RecentFileStorage();
        await recentFileStorage.addFile(validPaths.first);

        ref.read(actionHistoryProvider.notifier).addAction('Imported PDF');
      } else {
        log('No valid PDFs found');
      }
    }
  }

  Future<bool> isForFrontend(List<File> files) async {
    final int maxFileSizeForFrontend = 5 * 1024 * 1024;
    int totalSize = files.fold(0, (sum, file) => sum + file.lengthSync());
    return totalSize <= maxFileSizeForFrontend;
  }

  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  // save a single File
  static Future<String> saveFile(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Get the public Documents directory
      final Directory? directory = Directory('/storage/emulated/0/Documents');

      if (directory == null || !(await directory.exists())) {
        throw Exception('Unable to access public Documents directory');
      }

      log('Directory in save file: $directory');
      // if (await directory.exists()) {
      //   await directory.create(recursive: true);
      // }

      final String path = '${directory.path}/$fileName.pdf';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      log("path in save file: $path");
      return path;
    } else if (Platform.isIOS) {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$fileName.pdf';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } else {
      throw UnsupportedError('Unsupported Platform');
    }
  }

  static Future<String> fileSave(Uint8List bytes) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save AS PDF',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      fileName: 'new_pdf.pdf',
      bytes: bytes,
    );
    if (path != null) {
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } else {
      throw Exception("Unable to save File");
    }
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
    log('Saved File path: $paths');
    return paths;
  }

  // open a file
  static Future<void> openFile(String path) async {
    await OpenFile.open(path);
  }
}
