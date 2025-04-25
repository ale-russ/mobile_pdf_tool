import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_tool/routes/router.dart';

import 'providers/theme_provider.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // brightness: isDarkMode ? Brightness.dark : Brightness.light,
        // primarySwatch: Colors.amber,
        // scaffoldBackgroundColor: isDarkMode ? Color(0xFF00030C) : Colors.white,
        scaffoldBackgroundColor: TColor.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
