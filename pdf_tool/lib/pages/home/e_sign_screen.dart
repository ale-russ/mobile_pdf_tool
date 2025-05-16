import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final List<List<Point>> _drawingHistory = [];
  Uint8List? _signatureImage;
  Uint8List? _cachedSignature;
  bool _isDrawing = true;
  Offset _signaturePosition = const Offset(50, 50);
  double _signatureWidth = 150;
  double _signatureHeight = 50;
  double _initialSignatureWidth = 150;
  double _initialSignatureHeight = 50;
  int _currentPage = 1;
  late final PdfDocument _document;
  bool _isInteracting = false;
  double _initialScale = 1.0;
  bool _isLoading = true;
  bool _resizeMode = false;
  bool _isResizing = false;

  // @override
  // void initState() {
  //   _helper = ESignUtils();
  //   Future<void> initializeDocument() async {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     try {
  //       final pdfFile = File(widget.pdfPath);
  //       _document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     } catch (err) {
  //       log.e('Error initializing PDF document: $err');
  //       GlobalScaffold.showSnackbar(
  //         message: 'Error loading PDF: $err',
  //         backgroundColor: Colors.red,
  //       );
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }

  //   _helper.controller.onDrawEnd = () async {
  //     if (_helper.controller.points.isNotEmpty) {
  //       // Ensure points exist before adding
  //       _drawingHistory.add(List.from(_helper.controller.points));
  //       _cachedSignature = await _helper.controller.toPngBytes();
  //       setState(() {});
  //     }
  //   };

  //   initializeDocument();
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   _helper.controller.dispose();
  //   _document.dispose();
  //   super.dispose();
  // }

  // Future<void> _uploadSignature() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.image,
  //       allowMultiple: false,
  //     );

  //     if (result == null || result.files.isEmpty) return;

  //     final file = result.files.first;
  //     if (file.path != null) {
  //       final bytes = await File(file.path!).readAsBytes();
  //       setState(() {
  //         _signatureImage = bytes;
  //         _isDrawing = false;
  //         // Reset size for uploaded image
  //         _signatureWidth = 150;
  //         _signatureHeight = 50;
  //         _initialSignatureWidth = 150;
  //         _initialSignatureHeight = 50;
  //         _cachedSignature = null;
  //       });
  //     }
  //   } catch (err) {
  //     log.e('Error uploading signature: $err');
  //     GlobalScaffold.showSnackbar(
  //       message: 'Error Uploading Signature: $err',
  //       backgroundColor: Colors.red,
  //     );
  //   }
  // }

  // void _undoDrawing() {
  //   setState(() {
  //     log.i('Drawing history length: ${_drawingHistory.length}');
  //     if (_drawingHistory.isNotEmpty) {
  //       _drawingHistory.removeLast();
  //       if (_drawingHistory.isNotEmpty) {
  //         _helper.controller.points = List.from(_drawingHistory.last);
  //         _cachedSignature = null;
  //       } else {
  //         _helper.controller.clear();
  //         _cachedSignature = null;
  //       }
  //     } else {
  //       _helper.controller.clear();
  //       _cachedSignature = null;
  //     }
  //   });
  // }

  // void _startDrawing() {
  //   setState(() {
  //     _isDrawing = true;
  //     _signatureImage = null;
  //     _signatureWidth = 150;
  //     _signatureHeight = 50;
  //     _initialSignatureWidth = 150;
  //     _initialSignatureHeight = 50;
  //     _cachedSignature = null;
  //     _helper.controller.clear();
  //     _drawingHistory.clear();
  //     log.i('Drawing started: _isDrawing=$_isDrawing');
  //   });
  // }

  // Future<void> _signPdf() async {
  //   try {
  //     if (_isDrawing) {
  //       if (_helper.controller.isEmpty) {
  //         GlobalScaffold.showSnackbar(
  //           message: 'Please draw a signature',
  //           backgroundColor: Colors.amber,
  //         );
  //         return;
  //       }
  //       _signatureImage = await _helper.controller.toPngBytes();
  //     }

  //     if (_signatureImage == null) {
  //       GlobalScaffold.showSnackbar(
  //         message: 'No Signature Provided',
  //         backgroundColor: Colors.red,
  //       );
  //       return;
  //     }

  //     // Ensure the current page exists
  //     if (_currentPage < 1 || _currentPage > _document.pages.count) {
  //       GlobalScaffold.showSnackbar(
  //         message: 'Invalid page number',
  //         backgroundColor: Colors.red,
  //       );
  //       return;
  //     }

  //     // Add the signature to the specified page
  //     final page = _document.pages[_currentPage - 1];
  //     final pdfPageWidth = page.getClientSize().width;
  //     final pdfPageHeight = page.getClientSize().height;

  //     final screenWidth = MediaQuery.of(context).size.width;
  //     final screenHeight =
  //         MediaQuery.of(context).size.height - kToolbarHeight - 200 - 16;

  //     final pdfAspectRatio = pdfPageWidth / pdfPageHeight;
  //     final screenAspectRatio = screenWidth / screenHeight;

  //     double scaleFactor;
  //     double offsetX = 0;
  //     double offsetY = 0;

  //     if (pdfAspectRatio > screenAspectRatio) {
  //       // PDF is wider than the screen: fit by width
  //       scaleFactor = pdfPageWidth / screenWidth;
  //       final displayHeight = screenWidth / pdfAspectRatio;
  //       offsetY = (screenHeight - displayHeight) / 2;
  //     } else {
  //       // PDF is taller than the screen: fit by height
  //       scaleFactor = pdfPageHeight / screenHeight;
  //       final displayedWidth = screenHeight * pdfAspectRatio;
  //       offsetX = (screenWidth - displayedWidth) / 2;
  //     }

  //     final pdfX = (_signaturePosition.dx - offsetX) * scaleFactor;
  //     final pdfY = (_signaturePosition.dy - offsetY) * scaleFactor;
  //     final pdfWidth = _signatureWidth * scaleFactor;
  //     final pdfHeight = _signatureHeight * scaleFactor;

  //     log.i(
  //       'Screen position: ${_signaturePosition.dx}, ${_signaturePosition.dy}',
  //     );
  //     log.i('PDF position: $pdfX, $pdfY');
  //     log.i('PDF page size: $pdfPageWidth x $pdfPageHeight');
  //     log.i('Scaled size: $pdfWidth x $pdfHeight');

  //     final finalX = pdfX.clamp(0, pdfPageWidth - pdfWidth);
  //     final finalY = pdfY.clamp(0, pdfPageHeight - pdfHeight);

  //     final PdfBitmap signatureBitmap = PdfBitmap(_signatureImage!);
  //     page.graphics.drawImage(
  //       signatureBitmap,
  //       Rect.fromLTWH(
  //         finalX.toDouble(),
  //         finalY.toDouble(),
  //         pdfWidth,
  //         pdfHeight,
  //       ),
  //     );

  //     // Save the updated PDF
  //     final directory = await getApplicationSupportDirectory();
  //     final signedPath =
  //         '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
  //     final signedFile = File(signedPath);
  //     await signedFile.writeAsBytes(await _document.save());

  //     // Update the state
  //     ref.read(pdfStateProvider.notifier).setPdfPath([signedPath]);
  //     ref.read(pdfStateProvider.notifier).state = ref
  //         .read(pdfStateProvider)
  //         .copyWith(selectedPdfs: {signedPath});

  //     context.pop();
  //     GlobalScaffold.showSnackbar(
  //       message: 'PDF Signed Successfully',
  //       backgroundColor: AppColors.accentColor,
  //     );
  //   } catch (err) {
  //     log.e('Error signing PDF: $err');
  //     GlobalScaffold.showSnackbar(message: 'Error signing PDF: $err');
  //   }
  // }

  // void _toggleMode() {
  //   setState(() {
  //     _resizeMode = !_resizeMode;
  //     log.i('Mode toggled to: ${_resizeMode ? 'Resize' : 'Drag'}');
  //   });
  // }

  // @override
  // Widget build(BuildContext context) {
  //   log.i('isDrawing: $_isDrawing');
  //   log.i('signatureImage: $_signatureImage');
  //   log.i(
  //     'Dual conditions: ${(_isDrawing && _helper.controller.points.isNotEmpty)}',
  //   );
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('E-Sign PDF'),
  //       backgroundColor: AppColors.white,
  //       leading: IconButton(
  //         onPressed: () => Navigator.pop(context),
  //         icon: const Icon(Icons.arrow_back),
  //       ),
  //       elevation: 0.5,
  //       actions: [
  //         IconButton(onPressed: _undoDrawing, icon: const Icon(Icons.undo)),
  //         IconButton(
  //           onPressed: _toggleMode,
  //           icon: Icon(
  //             _resizeMode ? Icons.zoom_out_map : Icons.drag_handle,
  //             color:
  //                 _resizeMode ? AppColors.accentColor : AppColors.primaryColor,
  //           ),
  //           tooltip: _resizeMode ? 'Switch to Drag' : 'Switch to Resize',
  //         ),
  //       ],
  //     ),
  //     body:
  //         _isLoading
  //             ? Center(child: CircularProgressIndicator())
  //             : Column(
  //               children: [
  //                 // PDF Preview with Draggable and Resizable Signature
  //                 Expanded(
  //                   child: Stack(
  //                     children: [
  //                       SfPdfViewer.file(
  //                         File(widget.pdfPath),
  //                         initialPageNumber: _currentPage,
  //                         onPageChanged: (details) {
  //                           setState(() {
  //                             _currentPage = details.newPageNumber;
  //                           });
  //                         },
  //                       ),
  //                       if (_signatureImage != null ||
  //                           (_isDrawing &&
  //                               _helper.controller.points.isNotEmpty))
  //                         Positioned(
  //                           left: _signaturePosition.dx,
  //                           top: _signaturePosition.dy,
  //                           child: GestureDetector(
  //                             onScaleStart: (details) {
  //                               setState(() {
  //                                 _isInteracting = true;
  //                                 _isResizing = false;
  //                                 _initialScale = 1.0;
  //                                 _initialSignatureWidth = _signatureWidth;
  //                                 _initialSignatureHeight = _signatureHeight;
  //                               });
  //                             },
  //                             onScaleUpdate: (details) {
  //                               setState(() {
  //                                 // Handle dragging or resizing based on mode
  //                                 if (!_resizeMode || details.scale == 1.0) {
  //                                   _signaturePosition +=
  //                                       details.focalPointDelta;
  //                                   _signaturePosition = Offset(
  //                                     _signaturePosition.dx.clamp(
  //                                       0,
  //                                       MediaQuery.of(context).size.width -
  //                                           _signatureWidth,
  //                                     ),
  //                                     _signaturePosition.dy.clamp(
  //                                       0,
  //                                       MediaQuery.of(context).size.height -
  //                                           _signatureHeight -
  //                                           kToolbarHeight,
  //                                     ),
  //                                   );
  //                                 }
  //                                 if (_resizeMode && details.scale != 1.0) {
  //                                   _isResizing = true;
  //                                   double newScale =
  //                                       details.scale * _initialScale;
  //                                   _signatureWidth = (_initialSignatureWidth *
  //                                           newScale)
  //                                       .clamp(50, 300);
  //                                   _signatureHeight =
  //                                       (_initialSignatureHeight * newScale)
  //                                           .clamp(20, 150);
  //                                   _signaturePosition = Offset(
  //                                     _signaturePosition.dx -
  //                                         (_signatureWidth -
  //                                                 _initialSignatureWidth *
  //                                                     newScale) /
  //                                             2,
  //                                     _signaturePosition.dy -
  //                                         (_signatureHeight -
  //                                                 _initialSignatureHeight *
  //                                                     newScale) /
  //                                             2,
  //                                   );
  //                                   _signaturePosition = Offset(
  //                                     _signaturePosition.dx.clamp(
  //                                       0,
  //                                       MediaQuery.of(context).size.width -
  //                                           _signatureWidth,
  //                                     ),
  //                                     _signaturePosition.dy.clamp(
  //                                       0,
  //                                       MediaQuery.of(context).size.height -
  //                                           _signatureHeight -
  //                                           kToolbarHeight,
  //                                     ),
  //                                   );
  //                                 }
  //                               });
  //                             },
  //                             onScaleEnd: (_) {
  //                               setState(() {
  //                                 _isInteracting = false;
  //                                 _isResizing = false;
  //                               });
  //                             },
  //                             child: Container(
  //                               decoration: BoxDecoration(
  //                                 border:
  //                                     _isInteracting
  //                                         ? Border.all(
  //                                           color:
  //                                               _isResizing
  //                                                   ? Colors.green
  //                                                   : Colors.blue,
  //                                           width: 2,
  //                                         )
  //                                         : null,
  //                                 boxShadow:
  //                                     _isInteracting
  //                                         ? [
  //                                           BoxShadow(
  //                                             color: Colors.grey.withOpacity(
  //                                               0.5,
  //                                             ),
  //                                             spreadRadius: 2,
  //                                             blurRadius: 5,
  //                                             offset: const Offset(0, 3),
  //                                           ),
  //                                         ]
  //                                         : null,
  //                               ),
  //                               child:
  //                                   _isDrawing && _cachedSignature != null
  //                                       ? Image.memory(
  //                                         _cachedSignature!,
  //                                         width: _signatureWidth,
  //                                         height: _signatureHeight,
  //                                       )
  //                                       : _signatureImage != null
  //                                       ? Image.memory(
  //                                         _signatureImage!,
  //                                         width: _signatureWidth,
  //                                         height: _signatureHeight,
  //                                       )
  //                                       : const SizedBox.shrink(),
  //                             ),
  //                           ),
  //                         ),
  //                       Positioned(
  //                         right: 8,
  //                         bottom: MediaQuery.of(context).size.height * 0.1,
  //                         child: CircularAddButton(
  //                           onPressed: _signPdf,
  //                           icon: Icons.sign_language,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 // Signature Drawing Area
  //                 Container(
  //                   height: 120,
  //                   color: Colors.grey[200],
  //                   child:
  //                       _isDrawing
  //                           ? Signature(
  //                             controller: _helper.controller,
  //                             backgroundColor: Colors.grey[200]!,
  //                           )
  //                           : _signatureImage != null
  //                           ? Image.memory(
  //                             _signatureImage!,
  //                             height: 120,
  //                             width: double.infinity,
  //                             fit: BoxFit.contain,
  //                           )
  //                           : const Center(
  //                             child: Text('No signature uploaded'),
  //                           ),
  //                 ),
  //                 // Controls
  //                 Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: [
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: AppColors.primaryColor,
  //                           shape: BeveledRectangleBorder(
  //                             borderRadius: BorderRadius.circular(2),
  //                           ),
  //                         ),
  //                         onPressed: _startDrawing,
  //                         child: const Text(
  //                           'Draw Signature',
  //                           style: TextStyle(color: Colors.white),
  //                         ),
  //                       ),
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: AppColors.accentColor,
  //                           shape: BeveledRectangleBorder(
  //                             borderRadius: BorderRadius.circular(2),
  //                           ),
  //                         ),
  //                         onPressed: _uploadSignature,
  //                         child: const Text(
  //                           'Upload Signature',
  //                           style: TextStyle(color: Colors.white),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //   );
  // }
  @override
  void initState() {
    super.initState();
    _helper = ESignUtils();
    // _helper.controller.onDrawEnd = () async {
    //   if (!mounted || ref.read(eSignProvider).isLoading) return;
    //   if (_helper.controller.points.isNotEmpty) {
    //     final history = List<List<Point>>.from(
    //       ref.read(eSignProvider).drawingHistory,
    //     )..add(List.from([_helper.controller.points]));
    //     ref.read(eSignProvider.notifier).updateDrawingHistory(history);
    //     final cached = await _helper.controller.toPngBytes();
    //     ref.read(eSignProvider.notifier).setCachedSignature(cached);
    //     log.i(
    //       'Points captured: ${_helper.controller.points.length}, Cached signature updated',
    //     );
    //   }
    // };

    _controller.onDrawEnd = () async {
      if (!mounted || ref.read(eSignProvider).isLoading) return;
      if (_controller.points.isNotEmpty) {
        final history = List<List<Point>>.from(
          ref.read(eSignProvider).drawingHistory,
        )..add(List.from(_controller.points));
        ref.read(eSignProvider.notifier).updateDrawingHistory(history);
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
    ref.read(eSignProvider.notifier).resetSignature();
    _helper.controller.clear();
    log.i('Drawing started: isDrawing=${ref.read(eSignProvider).isDrawing}');
  }

  @override
  Widget build(BuildContext context) {
    final eSignState = ref.watch(eSignProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    log.i('isDrawing: ${eSignState.isDrawing}');
    log.i('signatureImage: ${eSignState.signatureImage}');
    log.i(
      'Dual conditions: ${(eSignState.isDrawing && _helper.controller.points.isNotEmpty)}',
    );

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
                                _helper.controller.points.isNotEmpty))
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
