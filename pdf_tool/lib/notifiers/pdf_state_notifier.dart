import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfState {
  final List<String>? pdfPaths;
  final int currentPage;
  final int totalPages;
  final Set<String> selectedPdfs;
  final String? splitPdfPath;
  final Uint8List? pdfBytes;
  final String? extractedText;

  PdfState({
    this.pdfPaths,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedPdfs = const <String>{},
    this.splitPdfPath = '',
    this.pdfBytes,
    this.extractedText = "",
  });

  PdfState copyWith({
    List<String>? pdfPaths,
    int? currentPage,
    int? totalPages,
    Set<String>? selectedPdfs,
    String? splitPdfPath,
    Uint8List? pdfBytes,
    String? extractedText,
  }) {
    return PdfState(
      pdfPaths: pdfPaths ?? this.pdfPaths,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedPdfs: selectedPdfs ?? this.selectedPdfs,
      splitPdfPath: splitPdfPath ?? this.splitPdfPath,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      extractedText: extractedText ?? this.extractedText,
    );
  }
}

class PdfStateNotifier extends StateNotifier<PdfState> {
  PdfStateNotifier() : super(PdfState());

  void setPdfPath(List<String> paths) {
    state = state.copyWith(pdfPaths: paths);
  }

  void setSelectedPdfs(List<String> selectedPdfs) {
    state = state.copyWith(selectedPdfs: selectedPdfs.toSet());
  }

  void clearSelectedPdfs() {
    state = state.copyWith(selectedPdfs: {});
  }

  void setPageInfo(int currentPage, int totalPages) {
    state = state.copyWith(currentPage: currentPage, totalPages: totalPages);
  }

  void updateSelectedPdfs(Set<String> selectedPdfs) {
    state = state.copyWith(selectedPdfs: selectedPdfs);
  }

  void clearPdfPaths() {
    state = state.copyWith(pdfPaths: []);
  }
}

// Extend for specific use cases
class PdfReaderNotifier extends PdfStateNotifier {}

class PdfSplitNotifier extends PdfStateNotifier {}

class PdfMergeNotifier extends PdfStateNotifier {}

class ImageToPdfNotifier extends PdfStateNotifier {
  ImageToPdfNotifier() : super();

  void setPdfBytes(Uint8List pdfBytes) =>
      state = state.copyWith(pdfBytes: pdfBytes);
  void clearImages() => state = state.copyWith(pdfBytes: null);
}

class ExtractTextFromImageNotifier extends PdfStateNotifier {
  ExtractTextFromImageNotifier() : super();

  void setExtractedText(String text) =>
      state = state.copyWith(extractedText: text);
}
