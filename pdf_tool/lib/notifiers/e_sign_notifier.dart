import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

class ESignState extends Equatable {
  final List<List<Point>> drawingHistory;
  final Uint8List? signatureImage;
  final Uint8List? cachedSignature;
  final bool isDrawing;
  final Offset signaturePosition;
  final double signatureWidth;
  final double signatureHeight;
  final double initialSignatureWidth;
  final double initialSignatureHeight;
  final int currentPage;
  final bool isInteracting;
  final double initialScale;
  final bool isLoading;
  final bool resizeMode;
  final bool isResizing;

  const ESignState({
    required this.drawingHistory,
    this.signatureImage,
    this.cachedSignature,
    required this.isDrawing,
    required this.signaturePosition,
    required this.signatureHeight,
    required this.signatureWidth,
    required this.initialScale,
    required this.initialSignatureHeight,
    required this.initialSignatureWidth,
    required this.currentPage,
    required this.isInteracting,
    required this.isLoading,
    required this.isResizing,
    required this.resizeMode,
  });

  factory ESignState.initial() => const ESignState(
    drawingHistory: [],
    signatureImage: null,
    cachedSignature: null,
    isDrawing: true,
    signaturePosition: Offset(50, 50),
    signatureHeight: 50,
    signatureWidth: 150,
    initialScale: 1.0,
    initialSignatureHeight: 50,
    initialSignatureWidth: 150,
    currentPage: 1,
    isInteracting: false,
    isLoading: true,
    isResizing: false,
    resizeMode: false,
  );

  ESignState copyWith({
    List<List<Point>>? drawingHistory,
    Uint8List? signatureImage,
    Uint8List? cachedSignature,
    bool? isDrawing,
    Offset? signaturePosition,
    double? signatureWidth,
    double? signatureHeight,
    double? initialSignatureWidth,
    double? initialSignatureHeight,
    int? currentPage,
    bool? isInteracting,
    double? initialScale,
    bool? isLoading,
    bool? resizeMode,
    bool? isResizing,
  }) {
    return ESignState(
      drawingHistory: drawingHistory ?? this.drawingHistory,
      isDrawing: isDrawing ?? this.isDrawing,
      signaturePosition: signaturePosition ?? this.signaturePosition,
      signatureHeight: signatureHeight ?? this.signatureHeight,
      signatureWidth: signatureWidth ?? this.signatureWidth,
      initialScale: initialScale ?? this.initialScale,
      initialSignatureHeight:
          initialSignatureHeight ?? this.initialSignatureHeight,
      initialSignatureWidth:
          initialSignatureWidth ?? this.initialSignatureWidth,
      currentPage: currentPage ?? this.currentPage,
      isInteracting: isInteracting ?? this.isInteracting,
      isLoading: isLoading ?? this.isLoading,
      isResizing: isResizing ?? this.isResizing,
      resizeMode: resizeMode ?? this.resizeMode,
    );
  }

  @override
  List<Object?> get props => [
    drawingHistory,
    signatureImage,
    cachedSignature,
    isDrawing,
    signaturePosition,
    signatureWidth,
    signatureHeight,
    initialScale,
    initialSignatureHeight,
    initialSignatureWidth,
    currentPage,
    isInteracting,
    isLoading,
    resizeMode,
    isResizing,
  ];
}

class ESignNotifier extends StateNotifier<ESignState> {
  ESignNotifier() : super(ESignState.initial());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void updateDrawingHistory(List<List<Point>> history) {
    state = state.copyWith(drawingHistory: history);
  }

  void setCachedSignature(Uint8List? cachedSignature) {
    state = state.copyWith(cachedSignature: cachedSignature);
  }

  void setSignatureImage(Uint8List? image) {
    state = state.copyWith(signatureImage: image);
  }

  void setIsDrawing(bool isDrawing) {
    state = state.copyWith(isDrawing: isDrawing);
  }

  void updateSignaturePosition(
    Offset position,
    double screenWidth,
    double screenHeight,
  ) {
    final newPosition = Offset(
      position.dx.clamp(0, screenWidth - state.signatureWidth),
      position.dy.clamp(0, state.signatureHeight),
    );

    state = state.copyWith(signaturePosition: newPosition);
  }

  void updateSignatureSize(
    double newScale,
    double screenWidth,
    double screenHeight,
  ) {
    final newWidth = (state.initialSignatureWidth * newScale).clamp(50, 300);
    final newHeight = (state.initialSignatureHeight * newScale).clamp(
      0,
      state.signatureHeight - kToolbarHeight,
    );
    final adjustedPosition = Offset(
      state.signaturePosition.dx -
          (newWidth - state.initialSignatureWidth * newScale) / 2,
      state.signaturePosition.dy - (newHeight - newScale) / 2,
    );

    final newPosition = Offset(
      adjustedPosition.dx.clamp(0, screenWidth - newWidth),
      adjustedPosition.dy.clamp(0, screenHeight - newHeight - kToolbarHeight),
    );
    state = state.copyWith(
      signatureWidth: newWidth.toDouble(),
      signatureHeight: newHeight.toDouble(),
      signaturePosition: newPosition,
    );
  }

  void setInitialScale(double scale) {
    state = state.copyWith(initialScale: scale);
  }

  void setInitialSignatureSize(double width, double height) {
    state = state.copyWith(
      initialSignatureWidth: width,
      initialSignatureHeight: height,
    );
  }

  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setInteracting(bool interacting) {
    state = state.copyWith(isInteracting: interacting);
  }

  void setResizing(bool resizing) {
    state = state.copyWith(isResizing: resizing);
  }

  void toggleMode() {
    state = state.copyWith(resizeMode: !state.resizeMode);
  }

  void resetSignature() {
    state = state.copyWith(
      isDrawing: true,
      signatureImage: null,
      cachedSignature: null,
      signatureWidth: 150,
      signatureHeight: 50,
      initialSignatureWidth: 150,
      initialSignatureHeight: 50,
      drawingHistory: [],
    );
  }
}

final eSignProvider = StateNotifierProvider<ESignNotifier, ESignState>(
  (ref) => ESignNotifier(),
);
