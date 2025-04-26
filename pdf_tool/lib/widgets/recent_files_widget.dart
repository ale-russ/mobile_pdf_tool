import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_tool/providers/pdf_state_provider.dart';

import '../providers/recent_files_provider.dart';
import '../utils/app_colors.dart';

class DisplayRecentFiles extends ConsumerWidget {
  const DisplayRecentFiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFilesAsync = ref.watch(recentFilesProvider);
    return recentFilesAsync.when(
      data: (files) {
        log('recentFiles: $files');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // for (final file in files)
            //   final filePath = path.basename(file);
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final filePath = files[index];
                  final fileName = path.basename(filePath.path);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: AppColors.pdfIconColor,
                      ),
                      title: Text(fileName),
                      subtitle: Text(filePath.openedAt.toIso8601String()),
                      trailing: Icon(
                        Icons.circle_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        ref.read(pdfStateProvider.notifier).setPdfPath([
                          filePath.path,
                        ]);
                        context.go('/display-pdf');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Failed to load recent files: $e'),
    );
  }
}
