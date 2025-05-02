import 'package:riverpod/riverpod.dart';

import '../providers/pdf_state_provider.dart';

class ReaderPdfNotifier extends StateNotifier<PdfState> {
  ReaderPdfNotifier() : super(PdfState());

  void setPdfPath(List<String> paths) {
    state = state.copyWith(pdfPaths: paths);
  }

  void setPageInfo(int current, int total) {
    state = state.copyWith(currentPage: current, totalPages: total);
  }
}
