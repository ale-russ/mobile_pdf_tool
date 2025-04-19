import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Editor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                log('result: $result');

                if (result != null) {
                  ref
                      .read(pdfStateProvider.notifier)
                      .setPdfPath(result.files.single.path!);
                  ref
                      .read(actionHistoryProvider.notifier)
                      .addAction('Imported PDF');
                  context.go('/editor');
                }
              },
              child: Text('Import PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
