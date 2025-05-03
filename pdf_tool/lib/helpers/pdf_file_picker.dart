import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_state_notifier.dart';
import '../providers/action_history_provider.dart';
import '../utils/recent_file_storage.dart';

class PdfFilePicker {
  static Future<void> pick({
    required WidgetRef ref,
    required PdfStateNotifier notifier,
    bool allowMultiple = true,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      final validPaths =
          result.paths
              .whereType<String>()
              .where((path) => File(path).existsSync())
              .toList();
      log('VALID PATHS: $validPaths');
      if (validPaths.isNotEmpty) {
        notifier.setPdfPath(validPaths);

        notifier.updateSelectedPdfs(validPaths.toSet());

        final recentFileStorage = RecentFileStorage();
        await recentFileStorage.addFile(validPaths.first);

        ref.read(actionHistoryProvider.notifier).addAction('Imported PDF');
      } else {
        log('No valid PDFs found');
      }
    }
  }
}
