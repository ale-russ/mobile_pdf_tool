// lib/providers/pdf_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/pdf_state_notifier.dart';
import 'pdf_state_provider.dart';

final pdfReaderProvider = StateNotifierProvider<PdfReaderNotifier, PdfState>(
  (ref) => PdfReaderNotifier(),
);

final pdfSplitProvider = StateNotifierProvider<PdfSplitNotifier, PdfState>(
  (ref) => PdfSplitNotifier(),
);

final pdfMergeProvider = StateNotifierProvider<PdfMergeNotifier, PdfState>(
  (ref) => PdfMergeNotifier(),
);
