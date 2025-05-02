import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_split_notifier.dart';
import 'pdf_state_provider.dart';

final pdfSplitProvider = StateNotifierProvider<SplitPdfNotifier, PdfState>((
  ref,
) {
  return SplitPdfNotifier();
});
