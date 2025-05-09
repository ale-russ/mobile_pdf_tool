import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_colors.dart';

class AddButton extends ConsumerWidget {
  const AddButton({
    super.key,
    this.notifier,
    this.title,
    this.isAddPDF = true,
    this.onPressed,
  });
  final notifier;
  final String? title;
  final bool isAddPDF;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('onPressed: $onPressed');
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
        // onPressed: () => onPressed ?? HelperMethods.pickFiles(ref),
        onPressed: onPressed,
        icon:
            isAddPDF
                ? Icon(Icons.add, color: AppColors.primaryColor)
                : const SizedBox.shrink(),
        label: Text(
          title ?? 'Add PDF',
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

class CircularAddButton extends ConsumerWidget {
  const CircularAddButton({
    super.key,
    this.notifier,
    this.title,
    this.isAddPDF = true,
    this.onPressed,
    this.icon,
  });
  final notifier;
  final String? title;
  final bool isAddPDF;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon ?? Icons.add, size: 25, color: AppColors.white),
      ),
    );
  }
}
