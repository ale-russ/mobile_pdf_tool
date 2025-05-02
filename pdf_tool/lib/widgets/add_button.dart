import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_colors.dart';
import '../utils/helper_methods.dart';

class AddButton extends ConsumerWidget {
  const AddButton({super.key, this.notifier});
  final notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.backgroundColor,
            offset: Offset(2, 2),
            blurRadius: 4,
            blurStyle: BlurStyle.normal,
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: () => HelperMethods.pickFiles(ref),
        icon: Icon(Icons.add, color: AppColors.primaryColor),
        label: const Text(
          'Add PDF',
          style: TextStyle(color: Color(0xFF111827)),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.backgroundColor,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
