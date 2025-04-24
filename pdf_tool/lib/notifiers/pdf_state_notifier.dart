import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_state_provider.dart';

class PdfStateNotifier extends StateNotifier<PdfState> {
  PdfStateNotifier() : super(PdfState());

  void setPdfPath(List<String> paths) {
    state = state.copyWith(pdfPaths: paths);
  }

  void setSelectedPdfs(List<String> selectedPdfs) {
    state = state.copyWith(selectedPdfs: selectedPdfs);
  }

  void clearSelectedPdfs() {
    state = state.copyWith(selectedPdfs: []);
  }

  void setPageInfo(int currentPage, int totalPages) {
    state = state.copyWith(currentPage: currentPage, totalPages: totalPages);
  }
}
