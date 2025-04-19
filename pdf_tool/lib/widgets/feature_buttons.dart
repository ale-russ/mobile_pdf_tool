import 'package:flutter/material.dart';

class FeatureButtons extends StatelessWidget {
  const FeatureButtons({
    super.key,
    required this.context,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final BuildContext context;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(100, 80),
        backgroundColor: Color(0xFF2A3A64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
