// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

import '../../providers/action_history_provider.dart';
import '../../providers/pdf_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/pdf_util.dart';
import '../../widgets/add_button.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  // void _pickFiles() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.any,
  //     allowMultiple: true,
  //     // allowedExtensions: ['pdf'],
  //   );

  //   log('Picked files: ${result?.paths}');
  //   if (result != null && result.files.isNotEmpty) {
  //     final validPaths =
  //         result.paths
  //             .whereType<String>()
  //             .where((path) => File(path).existsSync())
  //             .toList();
  //     log('Valid paths: $validPaths');
  //     if (validPaths.isNotEmpty) {
  //       List<String> paths = result.paths.whereType<String>().toList();
  //       ref.read(pdfStateProvider.notifier).setPdfPath(paths);
  //       ref.read(pdfStateProvider.notifier).state = ref
  //           .read(pdfStateProvider)
  //           .copyWith(selectedPdfs: validPaths);

  //       ref.read(actionHistoryProvider.notifier).addAction('Imported PDF');
  //     } else {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("No Valid PDFs found!")));
  //     }
  //   }
  // }

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
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('PDFs merged Successfully')));
        // await PdfUtil.openFile(savedPath);
        context.push('/home/success');
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

  void _removeFile(int index, List<String> selectedPDFs) {
    setState(() {
      selectedPDFs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfStateProvider);
    final selectedPdfs = pdfState.selectedPdfs;
    log('selectedPDFs: $selectedPdfs');
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Merge PDFs'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedPdfs.isNotEmpty)
              const Text(
                'Selected Files',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
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
                      : ReorderableListView.builder(
                        itemCount: selectedPdfs.length,
                        buildDefaultDragHandles: true,
                        onReorder:
                            (oldIndex, newIndex) =>
                                _onReorder(oldIndex, newIndex, selectedPdfs),

                        itemBuilder: (context, index) {
                          final filePath = selectedPdfs[index];
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
                                  color: Colors.grey,
                                ),
                                onPressed:
                                    () => _removeFile(index, selectedPdfs),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),

            // Add File Button
            AddButton(),
            const SizedBox(height: 16),

            // Merge Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () =>
                        selectedPdfs.length >= 2
                            ? _mergePDFs(ref, context)
                            : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Merge PDFs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
