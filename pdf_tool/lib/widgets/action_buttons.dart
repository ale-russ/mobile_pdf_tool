import 'package:flutter/material.dart';

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
        IconButton(icon: Icon(icon, color: Colors.grey), onPressed: onPressed),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
