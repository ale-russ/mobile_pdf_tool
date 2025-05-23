import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recent_files_model.dart';
import '../utils/recent_file_storage.dart';

final recentFilesProvider = FutureProvider<List<RecentFile>>((ref) async {
  final storage = RecentFileStorage();
  final result = await storage.getRecentFiles();
  log('Result in provider: $result');
  return result;
});
