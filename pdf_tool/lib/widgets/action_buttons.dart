import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.context,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final BuildContext context;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: TColor.primaryText, size: 25),
          onPressed: onPressed,
        ),
        // Text(label, style: TextStyle(color: TColor.primaryText, fontSize: 14)),
      ],
    );
  }
}
