import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:pdf_tool/providers/action_history_provider.dart';
import 'package:pdf_tool/providers/pdf_state_provider.dart';

Future<void> _mergePdfs(WidgetRef ref) async {
  var dio = Dio();
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
