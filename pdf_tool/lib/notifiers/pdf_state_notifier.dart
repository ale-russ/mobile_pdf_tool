import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pdf_state_provider.dart';

class PdfStateNotifier extends StateNotifier<PdfState> {
  PdfStateNotifier() : super(PdfState());

  void setPdfPath(List<String> paths) {
    state = state.copyWith(pdfPaths: paths);
  }

  // void addSelectedPdf(List<String> paths) {
  //   state = state.copyWith(
  //     pdfPaths: paths,
  //     selectedPdfs: [...state.selectedPdfs, paths],
  //   );
  // }

  void clearSelectedPdfs() {
    state = state.copyWith(selectedPdfs: []);
  }

  void setPageInfo(int currentPage, int totalPages) {
    state = state.copyWith(currentPage: currentPage, totalPages: totalPages);
  }
}
