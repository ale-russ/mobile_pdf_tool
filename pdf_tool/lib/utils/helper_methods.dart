import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class HelperMethods {
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
      image!,
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
