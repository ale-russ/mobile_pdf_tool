import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_colors.dart';

class SubmitButton extends ConsumerWidget {
  const SubmitButton({super.key, required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 40,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 40, right: 20, left: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TColor.primary,
          foregroundColor: TColor.white,
          shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Text(title),
      ),
    );
  }
}
