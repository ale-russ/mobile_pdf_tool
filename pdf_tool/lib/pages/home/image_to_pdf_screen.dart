import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../providers/pdf_state_provider.dart';
import '../../services/pdf_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/helper_methods.dart';
import '../../utils/image_utils.dart';
import '../../widgets/add_button.dart';
import '../../widgets/save_file_icon_widget.dart';

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
    // convertImagesToPdf(context);
    super.initState();
  }

  Future<void> convertImagesToPdf(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      if (await HelperMethods.requestCameraPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Storage Permission Denied"),
          ),
        );
        return;
      }

      // final result = await ImageUtils.imageToPdf();
      final response = await PdfServices().convertImageToPdf();
      log('response: $response');
      final result = await response.readAsBytes();
      final savedPath = await HelperMethods.fileSave(result);
      log('savedPath: $savedPath');
      // ref.read(imageToPdfProvider.notifier).setPdfBytes(result);
      ref.read(imageToPdfProvider.notifier).setPdfPath([savedPath]);
      log('processedImages: ${ref.watch(imageToPdfProvider).pdfPaths!.first}');
      setState(() {});
    } catch (err) {
      log("Error: $err");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error converting images to PDF: $err"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(imageToPdfProvider);
    log('pdfState: ${pdfState.pdfPaths}');
    log('isLoading: $isLoading');
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image To PDFs'),
          backgroundColor: AppColors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              ref.invalidate(imageToPdfProvider);
              context.pop();
            },
            icon: Icon(Icons.arrow_back),
          ),
          elevation: 0.5,
          // actions: [
          //   SaveFileIconWidget(
          //     backgroundColor: Color(0xffF8F2F1),
          //     icon: Icon(Icons.bookmark, color: Color(0xff9A5943)),
          //     onPressed: () async {
          //       final path = await FilePicker.platform.saveFile(
          //         dialogTitle: 'Save PDF',
          //         type: FileType.custom,
          //         fileName: 'converted_pdf.pdf',
          //         allowedExtensions: ['pdf'],
          //         bytes: pdfState.pdfBytes,
          //       );
          //       if (!mounted) return;
          //       if (path != null) {
          //         final file = File(path);
          //         await file.writeAsBytes(pdfState.pdfBytes as List<int>);
          //       }
          //     },
          //   ),
          // ],
        ),
        body: Stack(
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : (pdfState.pdfPaths == null || pdfState.pdfPaths!.isEmpty)
                ? Center(
                  child: Text(
                    'No File Loaded',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                )
                : SfPdfViewer.file(
                  key: _pdfViewerKey,
                  // pdfState.pdfBytes!,
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

            Positioned(
              right: 8,
              bottom: MediaQuery.of(context).size.height * 0.03,
              child: CircularAddButton(
                onPressed: () => convertImagesToPdf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
