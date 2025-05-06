import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SaveFileIconWidget extends StatelessWidget {
  const SaveFileIconWidget({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    required this.icon,
  });

  final Color? backgroundColor;

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xffF8F2F1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),

      child: IconButton(
        onPressed: onPressed,

        style: IconButton.styleFrom(padding: EdgeInsets.zero),
        icon: icon,
      ),
    );
  }
}
