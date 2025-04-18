import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_tool/screens/home.dart';
import 'package:pdf_tool/screens/pdf_editor_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/editor', builder: (context, state) => PdfEditorScreen()),
    ],
  );
});
