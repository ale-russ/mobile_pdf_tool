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
    return InkWell(
      onTap: onTap,
      // highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image.asset(
          //   icon,
          //   width: 15,
          //   height: 15,
          //   color: isSelected ? TColor.primary : TColor.placeholder,
          // ),
          Icon(
            icon,
            size: 15,
            color: isSelected ? TColor.primary : TColor.placeholder,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? TColor.primary : TColor.placeholder,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
