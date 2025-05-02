// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/pdf_state_provider.dart';
import '../../widgets/add_button.dart';
import '../../widgets/mereg_pdf_widget.dart';
import '../../widgets/recent_files_widget.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final int maxFileSizeForFrontend = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final pdfState = ref.watch(pdfStateProvider);
    final selectedPdfs = pdfState.selectedPdfs.toList();

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
            MergePdfWidget(),

            AddButton(),

            const SizedBox(height: 12),

            DisplayRecentFiles(),

            // const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
