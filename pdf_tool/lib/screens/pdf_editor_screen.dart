// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../providers/theme_provider.dart';

class PdfEditorScreen extends ConsumerWidget {
  const PdfEditorScreen({super.key});

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
                _buildActionButton(
                  context,
                  Icons.file_download,
                  'Import',
                  () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );
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
                _buildActionButton(
                  context,
                  Icons.file_upload,
                  'Export',
                  _exportPdf,
                ),
                _buildActionButton(
                  context,
                  Icons.undo,
                  'Undo',
                  canUndo
                      ? () {
                        ref.read(actionHistoryProvider.notifier).undo();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Undo action')));
                      }
                      : null,
                ),
                _buildActionButton(
                  context,
                  Icons.redo,
                  'Redo',
                  canRedo
                      ? () {
                        ref.read(actionHistoryProvider.notifier).redo();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Redo action')));
                      }
                      : null,
                ),
              ],
            ),
          ),
          // PDF Viewer
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Expanded(
              child:
                  pdfState.pdfPath != null
                      ? SizedBox(
                        child: SfPdfViewer.file(
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
                _buildFeatureButton(
                  context,
                  Icons.merge_type,
                  'Merge PDFs',
                  _mergePdfs,
                ),
                _buildFeatureButton(
                  context,
                  Icons.call_split,
                  'Split PDFs',
                  _splitPdfs,
                ),
                _buildFeatureButton(
                  context,
                  Icons.description,
                  'Convert to Word',
                  _convertToWord,
                ),
                _buildFeatureButton(
                  context,
                  Icons.layers,
                  'Extract Pages',
                  _extractPages,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: Colors.grey), onPressed: onPressed),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(100, 80),
        backgroundColor: Color(0xFF2A3A64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
