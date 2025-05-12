import 'package:flutter/material.dart';

class GlobalScaffold {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnackbar({
    required String message,
    Color backgroundColor = Colors.black87,
  }) {
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger != null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(backgroundColor: backgroundColor, content: Text(message)),
      );
    } else {
      debugPrint("ScaffoldMessenger is not initialized");
    }
  }
}
