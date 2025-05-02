import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_state_provider.dart';

class SplitPdfNotifier extends StateNotifier<PdfState> {
  SplitPdfNotifier() : super(PdfState());

  void setPdfPath(List<String> paths) {
    state = state.copyWith(pdfPaths: paths);
  }

  void setPageInfo(int current, int total) {
    state = state.copyWith(currentPage: current, totalPages: total);
  }
}
