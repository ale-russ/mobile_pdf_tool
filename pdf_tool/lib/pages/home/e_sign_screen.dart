import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../notifiers/e_sign_notifier.dart';
import '../../utils/e_sign_utils.dart';
import '../../providers/pdf_state_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/scaffold_utiltiy.dart';
import '../../widgets/add_button.dart';

class ESignScreen extends ConsumerStatefulWidget {
  const ESignScreen({super.key, required this.pdfPath});
  final String pdfPath;

  @override
  ConsumerState<ESignScreen> createState() => _ESignScreenState();
}

class _ESignScreenState extends ConsumerState<ESignScreen> {
  final Logger log = Logger();
  late final ESignUtils _helper;

  @override
  void initState() {
    super.initState();
    _helper = ESignUtils();
    _helper.controller.onDrawEnd = () async {
      if (!mounted || ref.read(eSignProvider).isLoading) return;
      if (_helper.controller.points.isNotEmpty) {
        final history = List<List<Point>>.from(
          ref.read(eSignProvider).drawingHistory,
        )..add(List.from(_helper.controller.points));
        ref.read(eSignProvider.notifier).updateDrawingHistory(history);
        final cached = await _helper.controller.toPngBytes();
        ref.read(eSignProvider.notifier).setCachedSignature(cached);
        log.i(
          'Points captured: ${_helper.controller.points.length}, Cached signature updated',
        );
      }
    };
    // Delay setLoading until the widget is mounted and start PDF loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eSignProvider.notifier).setLoading(true);
        _loadPdf();
      }
    });
  }

  Future<void> _loadPdf() async {
    try {
      await _helper.loadPdfDocument(widget.pdfPath);
      // Assuming ESignHelper could manage the document (optional enhancement)
      ref.read(eSignProvider.notifier).setLoading(false);
    } catch (e) {
      log.e('Error loading PDF: $e');
      GlobalScaffold.showSnackbar(
        message: 'Error loading PDF: $e',
        backgroundColor: Colors.red,
      );
      ref.read(eSignProvider.notifier).setLoading(false);
    }
  }

  @override
  void dispose() {
    _helper.dispose();
    super.dispose();
  }

  void _undoDrawing() {
    final history = List<List<Point>>.from(
      ref.read(eSignProvider).drawingHistory,
    );
    if (history.isNotEmpty) {
      history.removeLast();
      ref.read(eSignProvider.notifier).updateDrawingHistory(history);
      if (history.isNotEmpty) {
        _helper.controller.points = List.from(history.last);
        ref.read(eSignProvider.notifier).setCachedSignature(null);
      } else {
        _helper.controller.clear();
        ref.read(eSignProvider.notifier).setCachedSignature(null);
      }
    } else {
      _helper.controller.clear();
      ref.read(eSignProvider.notifier).setCachedSignature(null);
    }
    log.i('Drawing history length after undo: ${history.length}');
  }

  void _startDrawing() {
    _helper.controller.clear();
    ref.read(eSignProvider.notifier).resetSignature();
    log.i('Drawing started: isDrawing=${ref.read(eSignProvider).isDrawing}');
  }

  @override
  Widget build(BuildContext context) {
    final eSignState = ref.watch(eSignProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Sign PDF'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0.5,
        actions: [
          IconButton(onPressed: _undoDrawing, icon: const Icon(Icons.undo)),
          IconButton(
            onPressed: () => ref.read(eSignProvider.notifier).toggleMode(),
            icon: Icon(
              eSignState.resizeMode ? Icons.zoom_out_map : Icons.drag_handle,
              color:
                  eSignState.resizeMode
                      ? AppColors.accentColor
                      : AppColors.primaryColor,
            ),
            tooltip:
                eSignState.resizeMode ? 'Switch to Drag' : 'Switch to Resize',
          ),
        ],
      ),
      body:
          eSignState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SfPdfViewer.file(
                          File(widget.pdfPath),
                          initialPageNumber: eSignState.currentPage,
                          onPageChanged: (details) {
                            ref
                                .read(eSignProvider.notifier)
                                .setCurrentPage(details.newPageNumber);
                          },
                        ),
                        if (eSignState.signatureImage != null ||
                            (eSignState.isDrawing &&
                                eSignState.cachedSignature != null))
                          Positioned(
                            left: eSignState.signaturePosition.dx,
                            top: eSignState.signaturePosition.dy,
                            child: GestureDetector(
                              onScaleStart: (details) {
                                ref
                                    .read(eSignProvider.notifier)
                                    .setInteracting(true);
                                ref
                                    .read(eSignProvider.notifier)
                                    .setResizing(false);
                                ref
                                    .read(eSignProvider.notifier)
                                    .setInitialScale(1.0);
                                ref
                                    .read(eSignProvider.notifier)
                                    .setInitialSignatureSize(
                                      eSignState.signatureWidth,
                                      eSignState.signatureHeight,
                                    );
                              },
                              onScaleUpdate: (details) {
                                if (!eSignState.resizeMode ||
                                    details.scale == 1.0) {
                                  final newPosition =
                                      eSignState.signaturePosition +
                                      details.focalPointDelta;
                                  ref
                                      .read(eSignProvider.notifier)
                                      .updateSignaturePosition(
                                        newPosition,
                                        screenWidth,
                                        screenHeight,
                                      );
                                }
                                if (eSignState.resizeMode &&
                                    details.scale != 1.0) {
                                  ref
                                      .read(eSignProvider.notifier)
                                      .setResizing(true);
                                  final newScale =
                                      details.scale * eSignState.initialScale;
                                  ref
                                      .read(eSignProvider.notifier)
                                      .updateSignatureSize(
                                        newScale,
                                        screenWidth,
                                        screenHeight,
                                      );
                                }
                              },
                              onScaleEnd: (_) {
                                ref
                                    .read(eSignProvider.notifier)
                                    .setInteracting(false);
                                ref
                                    .read(eSignProvider.notifier)
                                    .setResizing(false);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      eSignState.isInteracting
                                          ? Border.all(
                                            color:
                                                eSignState.isResizing
                                                    ? Colors.green
                                                    : Colors.blue,
                                            width: 2,
                                          )
                                          : null,
                                  boxShadow:
                                      eSignState.isInteracting
                                          ? [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.5,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    eSignState.isDrawing &&
                                            eSignState.cachedSignature != null
                                        ? Image.memory(
                                          eSignState.cachedSignature!,
                                          width: eSignState.signatureWidth,
                                          height: eSignState.signatureHeight,
                                        )
                                        : eSignState.signatureImage != null
                                        ? Image.memory(
                                          eSignState.signatureImage!,
                                          width: eSignState.signatureWidth,
                                          height: eSignState.signatureHeight,
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          bottom: MediaQuery.of(context).size.height * 0.1,
                          child: CircularAddButton(
                            onPressed: () async {
                              final signature =
                                  eSignState.isDrawing
                                      ? await _helper.controller.toPngBytes()
                                      : eSignState.signatureImage;
                              if (eSignState.isDrawing &&
                                  _helper.controller.isEmpty) {
                                GlobalScaffold.showSnackbar(
                                  message: 'Please draw a signature',
                                  backgroundColor: Colors.amber,
                                );
                                return;
                              }
                              await _helper.signPdf(
                                signatureImage: signature,
                                pdfPath: widget.pdfPath,
                                signaturePosition: eSignState.signaturePosition,
                                signatureWidth: eSignState.signatureWidth,
                                signatureHeight: eSignState.signatureHeight,
                                currentPage: eSignState.currentPage,
                                screenWidth: screenWidth,
                                screenHeight:
                                    screenHeight - kToolbarHeight - 200 - 16,
                                onSuccess: (signedPath) {
                                  ref
                                      .read(pdfStateProvider.notifier)
                                      .setPdfPath([signedPath]);
                                  ref
                                      .read(pdfStateProvider.notifier)
                                      .state = ref
                                      .read(pdfStateProvider)
                                      .copyWith(selectedPdfs: {signedPath});
                                  context.pop();
                                  GlobalScaffold.showSnackbar(
                                    message: 'PDF Signed Successfully',
                                    backgroundColor: AppColors.accentColor,
                                  );
                                },
                                onError: (error) {
                                  GlobalScaffold.showSnackbar(
                                    message: error,
                                    backgroundColor: Colors.red,
                                  );
                                },
                              );
                            },
                            icon: Icons.sign_language,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 120,
                    color: Colors.grey[200],
                    child:
                        eSignState.isDrawing
                            ? Signature(
                              controller: _helper.controller,
                              backgroundColor: Colors.grey[200]!,
                            )
                            : eSignState.signatureImage != null
                            ? Image.memory(
                              eSignState.signatureImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            )
                            : const Center(
                              child: Text('No signature uploaded'),
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          onPressed: _startDrawing,
                          child: const Text(
                            'Draw Signature',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          onPressed: () async {
                            await _helper.uploadSignature(
                              onSuccess: (bytes) {
                                ref
                                    .read(eSignProvider.notifier)
                                    .setSignatureImage(bytes);
                                ref
                                    .read(eSignProvider.notifier)
                                    .setIsDrawing(false);
                              },
                              onError: (error) {
                                GlobalScaffold.showSnackbar(
                                  message: error,
                                  backgroundColor: Colors.red,
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Upload Signature',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
