import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

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
              .toList();
      log('Valid paths: $validPaths');
      if (validPaths.isNotEmpty) {
        List<String> paths = result.paths.whereType<String>().toList();
        ref.read(pdfStateProvider.notifier).setPdfPath(paths);
        ref.read(pdfStateProvider.notifier).state = ref
            .read(pdfStateProvider)
            .copyWith(selectedPdfs: validPaths);
        final recentFileStorage = RecentFileStorage();
        await recentFileStorage.addFile(validPaths.first);

        ref.read(actionHistoryProvider.notifier).addAction('Imported PDF');
      } else {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text("No Valid PDFs found!")));
        log('No Valid PDF Found');
      }
    }
  }

  Future<bool> isForFrontend(List<File> files) async {
    final int maxFileSizeForFrontend = 5 * 1024 * 1024;
    int totalSize = files.fold(0, (sum, file) => sum + file.lengthSync());
    return totalSize <= maxFileSizeForFrontend;
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<String> enahnceImage(String imagePath) async {
    // Read the image
    final img.Image? image = img.decodeImage(
      await File(imagePath).readAsBytes(),
    );
    if (image == null) throw Exception('Falied to decode image');

    // Adjust brightness and contrast
    img.Image adjustedImage = img.adjustColor(
      image,
      brightness: 1.2,
      contrast: 1.5,
    );

    // remove noice (simple median filter approximation)
    adjustedImage = img.noise(adjustedImage, 0.5);

    // Deskew the image (basic implementation using rotation)
    adjustedImage = img.copyRotate(
      adjustedImage,
      angle: _detectSkew(adjustedImage),
    );

    // Save the inhanced image
    final Directory directory = await getApplicationSupportDirectory();
    final String enhancedPath = '${directory.path}/enchanced_scan.jpg';
    await File(enhancedPath).writeAsBytes(img.encodeJpg(adjustedImage));

    return enhancedPath;
  }

  // Basic skew detection (simplified for demonestration)
  static double _detectSkew(img.Image image) {
    // In a real app, use Hough transform or a library like OpenCV for accurate deskew
    // This is a placeholder returning a small rotation angle
    return 0.5; // Rotate by 0.5 degrees (adjust based on actual detection)
  }
}
