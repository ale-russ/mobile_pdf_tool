import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class TabButton extends StatelessWidget {
  const TabButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final VoidCallback onTap;
  final String title;
  final bool isSelected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(color: TColor.primary),
      child: InkWell(
        onTap: onTap,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
              color: isSelected ? TColor.primary : TColor.placeholder,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? TColor.primary : TColor.placeholder,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
