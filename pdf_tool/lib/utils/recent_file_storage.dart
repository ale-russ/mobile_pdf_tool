import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recent_files_model.dart';

class RecentFileStorage {
  static const _key = 'recent_files';

  Future<List<RecentFile>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    log('jsonList: $jsonList');
    final result =
        jsonList
            .map((e) => RecentFile.fromJson(json.decode(e)))
            .toList()
            .take(3)
            .toList();

    log('Result in getRecentFiles: $result');

    return result;
  }

  Future<void> addFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentFiles();
    log('current: ${current.length}');

    // Remove if it already exists
    final updated = current.where((f) => f.path != filePath).toList();

    // Add on top
    updated.insert(0, RecentFile(path: filePath, openedAt: DateTime.now()));

    // Keep only latest 3
    final limited = updated.take(3).toList();

    final jsonList = limited.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }
}
