// PDF state provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_state_notifier.dart';

final pdfStateProvider = StateNotifierProvider<PdfStateNotifier, PdfState>((
  ref,
) {
  return PdfStateNotifier();
});

final pdfReaderProvider = StateNotifierProvider<PdfReaderNotifier, PdfState>(
  (ref) => PdfReaderNotifier(),
);

final pdfSplitProvider = StateNotifierProvider<PdfSplitNotifier, PdfState>(
  (ref) => PdfSplitNotifier(),
);

final pdfMergeProvider = StateNotifierProvider<PdfMergeNotifier, PdfState>(
  (ref) => PdfMergeNotifier(),
);

final imageToPdfProvider = StateNotifierProvider<ImageToPdfNotifier, PdfState>(
  (ref) => ImageToPdfNotifier(),
);

final extractTextFromImageProvider =
    StateNotifierProvider<ExtractTextFromImageNotifier, PdfState>(
      (ref) => ExtractTextFromImageNotifier(),
    );
