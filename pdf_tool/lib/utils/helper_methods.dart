import 'dart:io';

class HelperMethods {
  Future<bool> isForFrontend(List<File> files) async {
    final int maxFileSizeForFrontend = 5 * 1024 * 1024;
    int totalSize = files.fold(0, (sum, file) => sum + file.lengthSync());
    return totalSize <= maxFileSizeForFrontend;
  }
}
