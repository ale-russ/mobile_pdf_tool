import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_reader_notifier.dart';
import 'pdf_state_provider.dart';

final pdfReaderProvider = StateNotifierProvider<ReaderPdfNotifier, PdfState>((
  ref,
) {
  return ReaderPdfNotifier();
});
