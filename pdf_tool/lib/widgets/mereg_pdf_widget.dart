import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

import '../providers/action_history_provider.dart';
import '../providers/pdf_state_provider.dart';
import '../utils/app_colors.dart';
import '../utils/helper_methods.dart';
import '../utils/pdf_util.dart';
import 'submit_button.dart';

class MergePdfWidget extends ConsumerStatefulWidget {
  const MergePdfWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MergePdfWidgetState();
}

class _MergePdfWidgetState extends ConsumerState<MergePdfWidget> {
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;
  bool isLoading = false;

  void _mergePDFs(WidgetRef ref, BuildContext context) async {
    isLoading = true;
    setState(() {});
    final pdfState = ref.watch(pdfStateProvider);
    // Placeholder for merge logic (call backend)
    final List<String> pdfPaths = pdfState.selectedPdfs.toList();
    if (pdfPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select at least 2 PDFs to Merge"),
        ),
      );
      isLoading = false;
      setState(() {});
      return;
    }

    //calculate the total size file size
    int totalSize = (await Future.wait(
      pdfPaths.map((path) async => await File(path).length()),
    )).reduce((a, b) => a + b);

    try {
      // ref.read(pdfStateProvider.notifier).state = ref
      //     .read(pdfStateProvider)
      //     .copyWith(pdfPaths: []);
      ref.read(pdfStateProvider.notifier).clearPdfPaths();
      if (totalSize <= maxFileSizeForFrontend) {
        final Uint8List mergedBytes = await PdfUtil.mergePDFs(pdfPaths);
        final String savedPath = await HelperMethods.saveFile(
          mergedBytes,
          'merged_pdf.pdf',
        );
        log('Saved path: $savedPath');
        ref
            .read(actionHistoryProvider.notifier)
            .addAction("Merge PDFs (Frontend)");
        ref.read(pdfStateProvider.notifier).setPdfPath([savedPath]);
        ref.read(pdfStateProvider.notifier).clearSelectedPdfs();

        context.push('/home/success');
      } else {
        log("PDF file too big");
        return;
      }
    } catch (err) {
      log('Error: $err');
    }
    isLoading = false;
    setState(() {});
    ref.read(actionHistoryProvider.notifier).addAction('Merged PDFs');
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

  void _removeFile(int index, List<String> selectedPDFs) {
    setState(() {
      selectedPDFs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final pdfState = ref.watch(pdfStateProvider);
    final pdfState = ref.watch(pdfMergeProvider);
    final selectedPdfs = pdfState.selectedPdfs.toList();
    final notifier = ref.read(pdfSplitProvider.notifier);
    log('selectedPDFs: $selectedPdfs');
    return Expanded(
      child:
          selectedPdfs.isEmpty
              ? const Center(
                child: Text(
                  'No files added',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              )
              : Column(
                children: [
                  SizedBox(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: selectedPdfs.length,
                      buildDefaultDragHandles: true,
                      onReorder:
                          (oldIndex, newIndex) => _onReorder(
                            oldIndex,
                            newIndex,
                            selectedPdfs.toList(),
                          ),

                      itemBuilder: (context, index) {
                        final filePath = selectedPdfs.toList()[index];
                        final fileName = path.basename(filePath);
                        return Card(
                          key: ValueKey(filePath),
                          elevation: 2,
                          color: AppColors.backgroundColor,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.edit_document,
                              color: AppColors.pdfIconColor,
                            ),
                            title: Text(fileName),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () =>
                                      _removeFile(index, selectedPdfs.toList()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SubmitButton(
                    title: 'Merge PDF',
                    onPressed: () {
                      log('selectedPDFs: ${selectedPdfs.length}');
                      selectedPdfs.length >= 2
                          ? _mergePDFs(ref, context)
                          : ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.pdfIconColor,
                              content: Text(
                                'Please select more than 2 Files to be merged',
                                style: TextStyle(
                                  color: TColor.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                    },
                    isLoading: isLoading,
                  ),
                ],
              ),
    );
  }
}
