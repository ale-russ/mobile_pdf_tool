// PDF state provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_state_notifier.dart';

final pdfStateProvider = StateNotifierProvider<PdfStateNotifier, PdfState>((
  ref,
) {
  return PdfStateNotifier();
});

class PdfState {
  final String? pdfPath;
  final int currentPage;
  final int totalPages;

  PdfState({this.pdfPath, this.currentPage = 1, this.totalPages = 1});

  PdfState copyWith({String? pdfPath, int? currentPage, int? totalPages}) {
    return PdfState(
      pdfPath: pdfPath ?? this.pdfPath,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
