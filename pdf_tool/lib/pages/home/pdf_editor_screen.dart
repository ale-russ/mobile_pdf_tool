import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../providers/pdf_state_provider.dart';

class PdfEditorScreen extends ConsumerWidget {
  PdfEditorScreen({super.key});

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfStateProvider);

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
                                    onDocumentLoaded: (details) {},
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
}
