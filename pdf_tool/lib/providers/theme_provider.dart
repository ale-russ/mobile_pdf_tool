// Theme state provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateProvider<bool>(
  (ref) => true,
); // Default to dark mode
