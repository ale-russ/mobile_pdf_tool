import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf_tool/pages/home/home.dart';
import 'package:pdf_tool/pages/home/pdf_editor_screen.dart';

import '../pages/home/display_pdf.dart';
import '../pages/home/image_to_pdf_screen.dart';
import '../pages/home/merge_pdf.dart';
import '../pages/home/scan_pdf.dart';
import '../pages/home/split_pdf_screen.dart';
import '../pages/home/success_screen.dart';
import '../pages/settings_page.dart';
import '../pages/splash_screen.dart';
import '../widgets/main_scaffold.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: "/",
    routes: [
      // GoRoute(path: '/', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => HomeScreen(),
            routes: [
              GoRoute(
                path: '/editor',
                builder: (context, state) => PdfEditorScreen(),
              ),
              GoRoute(
                path: '/merge-pdf',
                builder: (context, state) => MergePdfScreen(),
              ),
              GoRoute(
                path: '/split-pdf',
                builder: (context, state) => SplitPdfScreen(),
              ),
              GoRoute(
                path: '/scan-document',
                builder: (context, state) => ScanPDFScreen(),
              ),
              GoRoute(
                path: '/image-pdf',
                builder: (context, state) => ImageToPdfScreen(),
              ),
              GoRoute(
                path: '/success',
                builder: (context, state) => SuccessScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/display-pdf',
            builder: (context, state) => DisplayPDFScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
