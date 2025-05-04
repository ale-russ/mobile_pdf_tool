import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../providers/pdf_state_provider.dart';
import '../../utils/image_utils.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool isLoading = false;
  @override
  void initState() {
    convertImagesToPdf(context);
    super.initState();
  }

  Future<void> convertImagesToPdf(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    if (!await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Storage Permission Denied"),
        ),
      );
      return;
    }

    await ImageUtils.imageToPdf(ref);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(imageToPdfProvider);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image To PDFs'),
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: const Color(0xFF111827),
        ),
        body:
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
                : isLoading
                ? Center(child: CircularProgressIndicator())
                : SfPdfViewer.file(
                  key: _pdfViewerKey,
                  File(pdfState.pdfPaths!.first),
                  onDocumentLoaded: (details) {
                    ref
                        .read(imageToPdfProvider.notifier)
                        .setPageInfo(1, details.document.pages.count);
                  },
                  onPageChanged:
                      (details) => ref
                          .read(imageToPdfProvider.notifier)
                          .setPageInfo(
                            details.newPageNumber,
                            pdfState.totalPages,
                          ),
                ),
      ),
    );
  }
}
