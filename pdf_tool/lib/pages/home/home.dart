import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/recent_files_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/merge_pdf.svg',
                      label: 'Merge PDF',
                      onTap: () => context.push('/home/merge-pdf'),
                      color: Color(0xffFFF1F1),
                      iconColor: Color(0xffF83A3C),
                    ),
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/scan_pdf.svg',
                      label: 'Scan PDF',
                      onTap: () => context.push("/home/scan-document"),
                      color: Color(0xffFFF7EB),
                      iconColor: Color(0xffFDAA31),
                    ),

                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/split_pdf.svg',
                      label: 'Extract PDF',
                      onTap: () => context.push('/home/split-pdf'),
                      color: Color(0xffFFF1F1),
                      iconColor: Color(0xffFDAA31),
                    ),
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/watermark_pdf.svg',
                      label: 'Pictures To PDF',
                      onTap: () => context.push('/home/image-pdf'),
                      color: Color(0xffF8F2F1),
                      // iconColor: Color(0xffFDAA31),
                      iconColor: Color(0Xff9A5943),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/e-scan_pdf.svg',
                      label: 'E-Sign PDF',
                      onTap: () => context.push('/home/sign-pdf'),
                      color: Color(0xffFFF1F1),
                      iconColor: Color(0xffFDAA31),
                    ),
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/protect_pdf.svg',
                      label: 'Protect PDF',
                      onTap: () {},
                      color: Color(0xffEBF7F6),
                      iconColor: Color(0xff40DAA4),
                    ),
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/compress_pdf.svg',
                      label: 'Compress PDF',
                      onTap: () {},
                      color: Color(0xffFFF7EB),
                      iconColor: Color(0xffFDA82F),
                    ),
                    BuildActionCard(
                      context: context,
                      icon: 'assets/img/all_tools.svg',
                      label: 'Extract Text From Image',
                      // label: 'Document To PDF',
                      onTap:
                          () => context.push("/home/extract-text-from-image"),
                      color: Color(0xffF0F5FC),
                      iconColor: Color(0xff5571FF),
                    ),
                  ],
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
}

class BuildActionCard extends StatelessWidget {
  const BuildActionCard({
    super.key,
    required this.context,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  final BuildContext context;
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon(icon, size: 20, color: iconColor),
            Container(
              width: 45,
              height: 45,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Color(0x1a000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SvgPicture.asset(icon, width: 18, height: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
