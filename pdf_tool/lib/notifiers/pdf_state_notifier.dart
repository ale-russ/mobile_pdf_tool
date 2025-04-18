import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_state_provider.dart';

class PdfStateNotifier extends StateNotifier<PdfState> {
  PdfStateNotifier() : super(PdfState());

  void setPdfPath(String path) {
    state = state.copyWith(pdfPath: path);
  }

  void setPageInfo(int currentPage, int totalPages) {
    state = state.copyWith(currentPage: currentPage, totalPages: totalPages);
  }
}
