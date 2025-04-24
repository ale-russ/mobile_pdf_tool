import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../utils/app_colors.dart';
import '../utils/pdf_util.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
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

  void _onReorder(int oldIndex, int newIndex, List<String> selectedPdfs) {
    final updatedList = [...selectedPdfs];

    // Adjust the new index if necessary
    if (newIndex > oldIndex) newIndex--;

    // Perform reordering
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    // update state using the notifier
    ref.read(pdfStateProvider.notifier).setSelectedPdfs(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfStateProvider);
    final selectedPdfs = pdfState.selectedPdfs;
    log('selectedPDFs: $selectedPdfs');
    return Scaffold(
      body:
          selectedPdfs.isEmpty
              ? Center(child: Text("No PDFs selected for merging"))
              : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      onReorder:
                          (oldIndex, newIndex) =>
                              _onReorder(oldIndex, newIndex, selectedPdfs),
                      itemCount: selectedPdfs.length,
                      itemBuilder: (context, index) {
                        final filePath = selectedPdfs[index];
                        final fileName = path.basename(filePath);
                        return Card(
                          color: TColor.primary,
                          key: ValueKey(filePath),
                          child: ListTile(
                            leading: Icon(
                              Icons.picture_as_pdf,
                              color: TColor.white,
                            ),
                            title: Text(
                              'File ${index + 1}',
                              style: TextStyle(
                                color: TColor.white,
                                // fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              fileName,
                              style: TextStyle(
                                color: TColor.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              Icons.drag_handle,
                              color: TColor.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: 40,
                      right: 20,
                      left: 20,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _mergePDFs(ref, context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: TColor.white,
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: Text("Merge PDF"),
                    ),
                  ),
                ],
              ),
    );
  }
}
