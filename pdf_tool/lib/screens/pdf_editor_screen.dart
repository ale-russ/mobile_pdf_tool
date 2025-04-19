// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/action_buttons.dart';
import '../widgets/feature_buttons.dart';

class PdfEditorScreen extends ConsumerWidget {
  PdfEditorScreen({super.key});

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfStateProvider);
    // final actionHistory = ref.watch(actionHistoryProvider);
    final canUndo = ref.watch(actionHistoryProvider.notifier).canUndo;
    final canRedo = ref.watch(actionHistoryProvider.notifier).canRedo;

    void _mergePdfs() async {
      // Placeholder for merge logic (call backend)
      ref.read(actionHistoryProvider.notifier).addAction('Merged PDFs');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Merging PDFs...')));
    }

    void _splitPdfs() async {
      // Placeholder for split logic (call backend)
      ref.read(actionHistoryProvider.notifier).addAction('Split PDFs');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Splitting PDFs...')));
    }

    void _convertToWord() async {
      // Placeholder for convert logic (call backend)
      ref.read(actionHistoryProvider.notifier).addAction('Converted to Word');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Converting to Word...')));
    }

    void _extractPages() async {
      // Placeholder for extract logic (call backend)
      ref.read(actionHistoryProvider.notifier).addAction('Extracted Pages');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Extracting Pages...')));
    }

    void _exportPdf() {
      // Placeholder for export logic
      ref.read(actionHistoryProvider.notifier).addAction('Exported PDF');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exporting PDF...')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text('PDF Editor'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeProvider)
                  ? Icons.brightness_7
                  : Icons.brightness_4,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).state = !ref.read(themeProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Bar
          Padding(
            padding: const EdgeInsets.all(4.0),
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
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );
                    log('Result: $result');
                    if (result != null) {
                      ref
                          .read(pdfStateProvider.notifier)
                          .setPdfPath(result.files.single.path!);
                      ref
                          .read(actionHistoryProvider.notifier)
                          .addAction('Imported PDF');
                    }
                  },
                ),
                ActionButtons(
                  context: context,
                  icon: Icons.file_upload,
                  label: 'Export',
                  onPressed: _exportPdf,
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
          // PDF Viewer
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child:
                  pdfState.pdfPath != null
                      ? SizedBox(
                        child: SfPdfViewer.file(
                          key: _pdfViewerKey,
                          File(pdfState.pdfPath!),
                          onDocumentLoaded: (details) {
                            ref
                                .read(pdfStateProvider.notifier)
                                .setPageInfo(1, details.document.pages.count);
                          },
                          onPageChanged: (details) {
                            ref
                                .read(pdfStateProvider.notifier)
                                .setPageInfo(
                                  details.newPageNumber,
                                  pdfState.totalPages,
                                );
                          },
                        ),
                      )
                      : Center(child: Text('No PDF loaded')),
            ),
          ),
          // Page Navigation
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed:
                      pdfState.currentPage > 1
                          ? () {
                            ref
                                .read(pdfStateProvider.notifier)
                                .setPageInfo(
                                  pdfState.currentPage - 1,
                                  pdfState.totalPages,
                                );
                          }
                          : null,
                ),
                Text('${pdfState.currentPage} of ${pdfState.totalPages}'),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed:
                      pdfState.currentPage < pdfState.totalPages
                          ? () {
                            ref
                                .read(pdfStateProvider.notifier)
                                .setPageInfo(
                                  pdfState.currentPage + 1,
                                  pdfState.totalPages,
                                );
                          }
                          : null,
                ),
              ],
            ),
          ),
          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                FeatureButtons(
                  context: context,
                  icon: Icons.merge_type,
                  label: 'Merge PDFs',
                  onPressed: _mergePdfs,
                ),
                FeatureButtons(
                  context: context,
                  icon: Icons.call_split,
                  label: 'Split PDFs',
                  onPressed: _splitPdfs,
                ),
                FeatureButtons(
                  context: context,
                  icon: Icons.description,
                  label: 'Convert to Word',
                  onPressed: _convertToWord,
                ),
                FeatureButtons(
                  context: context,
                  icon: Icons.layers,
                  label: 'Extract Pages',
                  onPressed: _extractPages,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
