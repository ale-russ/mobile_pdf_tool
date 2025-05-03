import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../providers/pdf_state_provider.dart';
import '../../widgets/add_button.dart';
import '../../widgets/submit_button.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfSplitProvider);
    final notifier = ref.read(pdfSplitProvider.notifier);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child:
                  pdfState.pdfPaths == null
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
            child: AddButton(notifier: notifier),
          ),
          SubmitButton(title: 'Split PDF', onPressed: () {}),
        ],
      ),
    );
  }
}
