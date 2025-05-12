import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../helpers/pdf_file_picker.dart';
import '../../providers/action_history_provider.dart';
import '../../providers/pdf_state_provider.dart';
import '../../services/pdf_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/helper_methods.dart';
import '../../widgets/add_button.dart';
import '../../widgets/save_file_icon_widget.dart';
import '../../widgets/search_widget.dart';
import '../../widgets/submit_button.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;
  final TextEditingController _splitPointsController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  bool isLoading = false;

  bool _showSearchField = false;

  @override
  void dispose() {
    _splitPointsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfSplitProvider);
    final notifier = ref.read(pdfSplitProvider.notifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Split PDFs'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              ref.invalidate(pdfSplitProvider);
              context.pop();
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Color(0xffFFF1F1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.symmetric(horizontal: 8),

              child: IconButton(
                color: Color(0xff9A5943),
                onPressed: () async {
                  setState(() => _showSearchField = !_showSearchField);
                },
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                icon: Icon(Icons.search),
              ),
            ),
            SaveFileIconWidget(
              onPressed: () async {
                final path = await FilePicker.platform.saveFile(
                  dialogTitle: 'Save PDF',
                  type: FileType.custom,
                  fileName: 'converted_pdf.pdf',
                  allowedExtensions: ['pdf'],
                  bytes: pdfState.pdfBytes,
                );
                if (!mounted) return;
                if (path != null) {
                  final file = File(path);
                  await file.writeAsBytes(pdfState.pdfBytes as List<int>);
                }
              },
              backgroundColor: Color(0xffFFF1F1),
              icon: Icon(Icons.bookmark, color: Color(0xff9A5943)),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: const Color(0xFF111827),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Column(
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
                              controller: _pdfViewerController,
                              File(pdfState.pdfPaths!.first),
                              currentSearchTextHighlightColor:
                                  AppColors.accentColor,
                              onDocumentLoaded: (details) {
                                ref
                                    .read(pdfStateProvider.notifier)
                                    .setPageInfo(
                                      1,
                                      details.document.pages.count,
                                    );
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
                if (pdfState.pdfPaths == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AddButton(
                      onPressed:
                          () => PdfFilePicker.pick(
                            ref: ref,
                            notifier: notifier,
                            allowMultiple: false,
                          ),
                    ),
                  ),
                SubmitButton(
                  title: 'Split PDF',
                  isLoading: isLoading,
                  onPressed:
                      () => _splitPDFs(context, _splitPointsController, ref),
                ),
              ],
            ),
            if (_showSearchField)
              Positioned(
                top: 10,
                child: SearchBarWidget(
                  searchController: _searchController,
                  pdfViewerController: _pdfViewerController,
                ),
              ),
            if (pdfState.pdfPaths != null)
              Positioned(
                right: 8,
                bottom: MediaQuery.of(context).size.height * 0.2,
                child: CircularAddButton(
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
      final notifier = ref.read(pdfSplitProvider.notifier);
      return AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text("Split PDF", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: TColor.black),
          decoration: InputDecoration(
            labelText: 'Split pages (e.g. 3,7 or 2-5)',
            labelStyle: TextStyle(fontSize: 12, color: AppColors.textColor),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = "";
              setState(() {});
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderColor),
                borderRadius: BorderRadius.circular(8),
                color: Colors.red,
              ),
              child: Text('Cancel', style: TextStyle(color: TColor.white)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Please enter pages to split'),
                  ),
                );
                return;
              }

              final pdfState = ref.watch(pdfSplitProvider);
              final pdfPaths = pdfState.pdfPaths;
              if (pdfPaths == null || pdfPaths.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('No PDF selected to split.'),
                  ),
                );
                return;
              }

              final String pdfPath = pdfState.pdfPaths!.first;
              final int fileSize = await File(pdfPath).length();
              context.pop();
              setState(() {
                isLoading = true;
              });
              try {
                if (fileSize <= maxFileSizeForFrontend) {
                  // process in frontend
                  // final List<Uint8List> splitBytes = await PdfUtil.splitPdf(
                  //   pdfPath,
                  //   _splitPointsController.text.trim(),
                  // );

                  final File responseFile = await PdfServices().splitPdfs(
                    pdfPath,
                    _splitPointsController.text.trim(),
                  );
                  final splittedPdf = await responseFile.readAsBytes();
                  final savedPaths = await HelperMethods.fileSave(splittedPdf);

                  ref
                      .read(actionHistoryProvider.notifier)
                      .addAction('Split PDFs (Frontend)');
                  if (savedPaths.isNotEmpty) {
                    ref.read(pdfStateProvider.notifier).setPdfPath([
                      savedPaths,
                    ]);

                    notifier.setSelectedPdfs([savedPaths]);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF split into ${savedPaths.length} files',
                        ),
                      ),
                    );
                    await HelperMethods.openFile(savedPaths);
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
                      backgroundColor: Colors.red,
                      content: Text(
                        'File too large. Backend splitting not yet implemented.',
                      ),
                    ),
                  );
                }
              } catch (err) {
                log('Error: $err');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Error: ${err.toString()}'),
                  ),
                );
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderColor),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryColor,
              ),
              child: Text(
                'Split Pages',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ],
      );
    },
  );
}
