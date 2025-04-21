// PDF state provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/pdf_state_notifier.dart';

final pdfStateProvider = StateNotifierProvider<PdfStateNotifier, PdfState>((
  ref,
) {
  return PdfStateNotifier();
});

class PdfState {
  final List<String>? pdfPaths;
  final int currentPage;
  final int totalPages;
  final List<String> selectedPdfs;

  PdfState({
    this.pdfPaths,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedPdfs = const [],
  });

  PdfState copyWith({
    List<String>? pdfPaths,
    int? currentPage,
    int? totalPages,
    List<String>? selectedPdfs,
  }) {
    return PdfState(
      pdfPaths: pdfPaths ?? this.pdfPaths,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedPdfs: selectedPdfs ?? [],
    );
  }
}
