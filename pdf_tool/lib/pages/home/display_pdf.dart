import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../helpers/pdf_file_picker.dart';
import '../../providers/pdf_state_provider.dart';
import '../../widgets/add_button.dart';

class DisplayPDFScreen extends ConsumerWidget {
  DisplayPDFScreen({super.key});

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfStateProvider);
    final notifier = ref.read(pdfStateProvider.notifier);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child:
                      (pdfState.pdfPaths == null || pdfState.pdfPaths!.isEmpty)
                          ? Center(
                            child: Text(
                              'No PDF loaded',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          )
                          : SfPdfViewer.file(
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
                          ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: AddButton(
                  title: 'Open PDF',
                  onPressed:
                      () => PdfFilePicker.pick(
                        ref: ref,
                        notifier: notifier,
                        allowMultiple: false,
                      ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: CircularAddButton(
              onPressed: () {
                context.push("/home/sign-pdf", extra: pdfState.pdfPaths!.first);
              },
              icon: Icons.sign_language,
            ),
          ),
        ],
      ),
    );
  }
}
