import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pdf_file_picker.dart';
import '../../providers/pdf_state_provider.dart';
import '../../widgets/add_button.dart';
import '../../widgets/mereg_pdf_widget.dart';
import '../../widgets/recent_files_widget.dart';
import '../../widgets/save_file_icon_widget.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfMergeProvider);
    final selectedPdfs = pdfState.selectedPdfs.toList();
    final notifier = ref.read(pdfMergeProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Merge PDFs'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            ref.invalidate(pdfMergeProvider);
            context.pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
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
            MergePdfWidget(),

            AddButton(
              onPressed: () {
                PdfFilePicker.pick(notifier: notifier, ref: ref);
              },
            ),

            const SizedBox(height: 12),

            DisplayRecentFiles(),
          ],
        ),
      ),
    );
  }
}
