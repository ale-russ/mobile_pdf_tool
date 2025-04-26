import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_colors.dart';
import '../../widgets/recent_files_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'PDF Tool',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.file_open_outlined,
                  label: 'Create PDF',
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  icon: Icons.merge_type,
                  label: 'Merge PDFs',
                  onTap: () => context.push('/home/merge-pdf'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.account_tree_outlined,
                  label: 'Split PDF',
                  onTap: () {},
                ),
                _buildActionCard(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Scan Document',
                  onTap: () => context.push('/home/scan-document'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            DisplayRecentFiles(),
          ],
        ),
      ),
    );
  }

  // Quick Action Card
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primaryColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent File Tile
  Widget _buildRecentFileTile(String fileName, String date) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Icon(Icons.insert_drive_file, color: AppColors.pdfIconColor),
      title: Text(fileName),
      subtitle: Text(date),
      trailing: Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }
}
