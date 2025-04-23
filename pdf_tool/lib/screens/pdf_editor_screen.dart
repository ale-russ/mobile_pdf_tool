// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../providers/theme_provider.dart';
import '../services/pdf_services.dart';
import '../utils/pdf_util.dart';
import '../widgets/action_buttons.dart';
import '../widgets/feature_buttons.dart';

class PdfEditorScreen extends ConsumerWidget {
  PdfEditorScreen({super.key});

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _splitPointsController = TextEditingController();
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  void _mergePDFs(WidgetRef ref, BuildContext context) async {
    final pdfState = ref.watch(pdfStateProvider);
    // Placeholder for merge logic (call backend)
    final List<String> pdfPaths = pdfState.selectedPdfs;
    if (pdfPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least 2 PDFs to Merge")),
      );
      return;
    }

    //calculate the total size file size
    int totalSize = (await Future.wait(
      pdfPaths.map((path) async => await File(path).length()),
    )).reduce((a, b) => a + b);

    try {
      ref.read(pdfStateProvider.notifier).state = ref
          .read(pdfStateProvider)
          .copyWith(pdfPaths: []);
      if (totalSize <= maxFileSizeForFrontend) {
        // Process on frontend
        final Uint8List mergedBytes = await PdfUtil.mergePDFs(pdfPaths);
        final String savedPath = await PdfUtil.saveFile(
          mergedBytes,
          'merged_pdf.pdf',
        );
        ref
            .read(actionHistoryProvider.notifier)
            .addAction("Merge PDFs (Frontend)");
        ref.read(pdfStateProvider.notifier).setPdfPath([savedPath]);
        ref.read(pdfStateProvider.notifier).clearSelectedPdfs();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDFs merged Successfully')));
        await PdfUtil.openFile(savedPath);
      } else {
        log("PDF file too big");
        return;
      }
    } catch (err) {
      log('Error: $err');
    }

    ref.read(actionHistoryProvider.notifier).addAction('Merged PDFs');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Merging PDFs...')));
  }

  void _convertToWord(WidgetRef ref, BuildContext context) async {
    final pdfState = ref.watch(pdfStateProvider);

    if (pdfState.pdfPaths == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No PDF Loaded')));
      return;
    }

    final String pdfPath = pdfState.pdfPaths!.first;

    var response = await PdfServices().convertPdfToWord(pdfPath);

    log('response: $response');

    ref.read(actionHistoryProvider.notifier).addAction('Converted to Word');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Converting to Word...')));
  }

  void _extractPages(WidgetRef ref, BuildContext context) async {
    // Placeholder for extract logic (call backend)
    ref.read(actionHistoryProvider.notifier).addAction('Extracted Pages');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Extracting Pages...')));
  }

  void _exportPdf(WidgetRef ref, BuildContext context) {
    // Placeholder for export logic
    ref.read(actionHistoryProvider.notifier).addAction('Exported PDF');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporting PDF...')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfStateProvider);
    // final actionHistory = ref.watch(actionHistoryProvider);
    final canUndo = ref.watch(actionHistoryProvider.notifier).canUndo;
    final canRedo = ref.watch(actionHistoryProvider.notifier).canRedo;

    return Scaffold(
      body: Column(
        children: [
          // PDF Viewer
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child:
                  pdfState.pdfPaths == null
                      ? Center(child: Text('No PDF loaded'))
                      : pdfState.pdfPaths!.length == 1
                      ? SfPdfViewer.file(
                        key: _pdfViewerKey,
                        File(pdfState.pdfPaths!.first),
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
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: pdfState.pdfPaths!.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final path = pdfState.pdfPaths![index];
                          return Card(
                            child: Column(
                              children: [
                                Expanded(
                                  child: SfPdfViewer.file(
                                    File(path),
                                    canShowScrollStatus: false,
                                    canShowPaginationDialog: false,
                                    pageLayoutMode: PdfPageLayoutMode.single,
                                    pageSpacing: 0,
                                    initialZoomLevel: 0.3,
                                    enableTextSelection: false,
                                    onDocumentLoaded: (details) {
                                      // Optional: preload preview data or page count
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    'File ${index + 1}',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _splitPDFs(
    BuildContext context,
    TextEditingController controller,
    WidgetRef ref,
  ) async => await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Split PDF"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Split pages (e.g. 3,7 or 2-5)',
            hintText: 'Enter pages to split after (e.g, 3,7 or 1,3-5)',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: false),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter pages to split')),
                );
                return;
              }
              final pdfState = ref.watch(pdfStateProvider);

              final String pdfPath = pdfState.pdfPaths!.first;
              final int fileSize = await File(pdfPath).length();

              try {
                if (fileSize <= maxFileSizeForFrontend) {
                  // process in frontend
                  final List<Uint8List> splitBytes = await PdfUtil.splitPdf(
                    pdfPath,
                    _splitPointsController.text.trim(),
                  );
                  final List<String> savedPaths =
                      await PdfUtil.saveMultipleFiles(splitBytes, 'split');
                  ref
                      .read(actionHistoryProvider.notifier)
                      .addAction('Split PDFs (Frontend)');
                  if (savedPaths.isNotEmpty) {
                    // Update the viewed PDF to the first split file
                    ref.read(pdfStateProvider.notifier).setPdfPath(savedPaths);

                    // update the selectedPDFs to only include the split files
                    ref.read(pdfStateProvider.notifier).state = ref
                        .read(pdfStateProvider)
                        .copyWith(selectedPdfs: savedPaths);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF split into ${savedPaths.length} files',
                        ),
                      ),
                    );
                    await PdfUtil.openFile(savedPaths.first);
                    context.pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("No Files were created during splitting"),
                      ),
                    );
                  }
                } else {
                  // TODO backend logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'File too large. Backend splitting not yet implemented.',
                      ),
                    ),
                  );
                }
              } catch (err) {
                log('Error: $err');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${err.toString()}')),
                );
              }
            },
            child: Text('Split Pages'),
          ),
        ],
      );
    },
  );
}
