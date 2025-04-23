import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/action_buttons.dart';
import 'main_tabview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(actionHistoryProvider.notifier).canUndo;
    final canRedo = ref.watch(actionHistoryProvider.notifier).canRedo;
    return Scaffold(
      appBar: AppBar(
        // title: Text('PDF Editor')
        // backgroundColor: TColor.black,
        backgroundColor: TColor.white,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButtons(
                context: context,
                icon: Icons.file_download,
                label: 'Import',
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
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
                      List<String> paths =
                          result.paths.whereType<String>().toList();
                      ref.read(pdfStateProvider.notifier).setPdfPath(paths);
                      ref.read(pdfStateProvider.notifier).state = ref
                          .read(pdfStateProvider)
                          .copyWith(selectedPdfs: validPaths);

                      ref
                          .read(actionHistoryProvider.notifier)
                          .addAction('Imported PDF');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("No Valid PDFs found!")),
                      );
                    }
                  }
                },
              ),
              ActionButtons(
                context: context,
                icon: Icons.file_upload,
                label: 'Export',
                // onPressed: () => _exportPdf(ref, context),
                onPressed: () {},
              ),
              ActionButtons(
                context: context,
                icon: Icons.undo,
                label: 'Undo',
                onPressed:
                    canUndo
                        ? () {
                          ref.read(actionHistoryProvider.notifier).undo();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Undo action')),
                          );
                        }
                        : null,
              ),
              ActionButtons(
                context: context,
                icon: Icons.redo,
                label: 'Redo',
                onPressed:
                    canRedo
                        ? () {
                          ref.read(actionHistoryProvider.notifier).redo();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Redo action')),
                          );
                        }
                        : null,
              ),
            ],
          ),
        ),
      ),
      body: MainTabViewScreen(),
    );
  }
}
