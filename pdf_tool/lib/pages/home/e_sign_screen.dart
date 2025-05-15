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

// class _ESignScreenState extends ConsumerState<ESignScreen> {
//   final Logger log = Logger();
//   final SignatureController _controller = SignatureController(
//     penStrokeWidth: 3,
//     penColor: Colors.black,
//     exportBackgroundColor: Colors.transparent,
//   );

//   final List<List<Point>> _drawingHistory = [];
//   Uint8List? _signatureImage;
//   Uint8List? _cachedSignature;
//   bool _isDrawing = true;
//   Offset _signaturePosition = const Offset(50, 50);
//   double _signatureWidth = 150;
//   double _signatureHeight = 50;
//   double _initialSignatureWidth = 150;
//   double _initialSignatureHeight = 50;
//   int _currentPage = 1;
//   late final PdfDocument _document;
//   bool _isInteracting = false;
//   double _initialScale = 1.0;
//   bool _isLoading = true;
//   bool _resizeMode = false;
//   bool _isResizing = false;

//   @override
//   void initState() {
//     Future<void> initializeDocument() async {
//       try {
//         final pdfFile = File(widget.pdfPath);
//         _document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
//         setState(() {
//           _isLoading = false;
//         });
//       } catch (err) {
//         log.e('Error initializing PDF document: $err');
//         GlobalScaffold.showSnackbar(
//           message: 'Error loading PDF: $err',
//           backgroundColor: Colors.red,
//         );
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }

//     _controller.onDrawEnd = () async {
//       if (_controller.points.isNotEmpty) {
//         // Ensure points exist before adding
//         _drawingHistory.add(List.from(_controller.points));
//         _cachedSignature = await _controller.toPngBytes();
//         setState(() {});
//       }
//     };

//     initializeDocument();
//     super.initState();
//   }

// @override
// void dispose() {
//   _controller.dispose();
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
//         _controller.points = List.from(_drawingHistory.last);
//         _cachedSignature = null;
//       } else {
//         _controller.clear();
//         _cachedSignature = null;
//       }
//     } else {
//       _controller.clear();
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
//     _controller.clear();
//     _drawingHistory.clear();
//     log.i('Drawing started: _isDrawing=$_isDrawing');
//   });
// }

// Future<void> _signPdf() async {
//   try {
//     if (_isDrawing) {
//       if (_controller.isEmpty) {
//         GlobalScaffold.showSnackbar(
//           message: 'Please draw a signature',
//           backgroundColor: Colors.amber,
//         );
//         return;
//       }
//       _signatureImage = await _controller.toPngBytes();
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('E-Sign PDF'),
//         backgroundColor: AppColors.white,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back),
//         ),
//         elevation: 0.5,
//         actions: [
//           IconButton(onPressed: _undoDrawing, icon: const Icon(Icons.undo)),
//           IconButton(
//             onPressed: _toggleMode,
//             icon: Icon(
//               _resizeMode ? Icons.zoom_out_map : Icons.drag_handle,
//               color:
//                   _resizeMode ? AppColors.accentColor : AppColors.primaryColor,
//             ),
//             tooltip: _resizeMode ? 'Switch to Drag' : 'Switch to Resize',
//           ),
//         ],
//       ),
//       body:
//           _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : Column(
//                 children: [
//                   // PDF Preview with Draggable and Resizable Signature
//                   Expanded(
//                     child: Stack(
//                       children: [
//                         SfPdfViewer.file(
//                           File(widget.pdfPath),
//                           initialPageNumber: _currentPage,
//                           onPageChanged: (details) {
//                             setState(() {
//                               _currentPage = details.newPageNumber;
//                             });
//                           },
//                         ),
//                         if (_signatureImage != null ||
//                             (_isDrawing && _controller.points.isNotEmpty))
//                           Positioned(
//                             left: _signaturePosition.dx,
//                             top: _signaturePosition.dy,
//                             child: GestureDetector(
//                               onScaleStart: (details) {
//                                 setState(() {
//                                   _isInteracting = true;
//                                   _isResizing = false;
//                                   _initialScale = 1.0;
//                                   _initialSignatureWidth = _signatureWidth;
//                                   _initialSignatureHeight = _signatureHeight;
//                                 });
//                               },
//                               onScaleUpdate: (details) {
//                                 setState(() {
//                                   // Handle dragging or resizing based on mode
//                                   if (!_resizeMode || details.scale == 1.0) {
//                                     _signaturePosition +=
//                                         details.focalPointDelta;
//                                     _signaturePosition = Offset(
//                                       _signaturePosition.dx.clamp(
//                                         0,
//                                         MediaQuery.of(context).size.width -
//                                             _signatureWidth,
//                                       ),
//                                       _signaturePosition.dy.clamp(
//                                         0,
//                                         MediaQuery.of(context).size.height -
//                                             _signatureHeight -
//                                             kToolbarHeight,
//                                       ),
//                                     );
//                                   }
//                                   if (_resizeMode && details.scale != 1.0) {
//                                     _isResizing = true;
//                                     double newScale =
//                                         details.scale * _initialScale;
//                                     _signatureWidth = (_initialSignatureWidth *
//                                             newScale)
//                                         .clamp(50, 300);
//                                     _signatureHeight =
//                                         (_initialSignatureHeight * newScale)
//                                             .clamp(20, 150);
//                                     _signaturePosition = Offset(
//                                       _signaturePosition.dx -
//                                           (_signatureWidth -
//                                                   _initialSignatureWidth *
//                                                       newScale) /
//                                               2,
//                                       _signaturePosition.dy -
//                                           (_signatureHeight -
//                                                   _initialSignatureHeight *
//                                                       newScale) /
//                                               2,
//                                     );
//                                     _signaturePosition = Offset(
//                                       _signaturePosition.dx.clamp(
//                                         0,
//                                         MediaQuery.of(context).size.width -
//                                             _signatureWidth,
//                                       ),
//                                       _signaturePosition.dy.clamp(
//                                         0,
//                                         MediaQuery.of(context).size.height -
//                                             _signatureHeight -
//                                             kToolbarHeight,
//                                       ),
//                                     );
//                                   }
//                                 });
//                               },
//                               onScaleEnd: (_) {
//                                 setState(() {
//                                   _isInteracting = false;
//                                   _isResizing = false;
//                                 });
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   border:
//                                       _isInteracting
//                                           ? Border.all(
//                                             color:
//                                                 _isResizing
//                                                     ? Colors.green
//                                                     : Colors.blue,
//                                             width: 2,
//                                           )
//                                           : null,
//                                   boxShadow:
//                                       _isInteracting
//                                           ? [
//                                             BoxShadow(
//                                               color: Colors.grey.withOpacity(
//                                                 0.5,
//                                               ),
//                                               spreadRadius: 2,
//                                               blurRadius: 5,
//                                               offset: const Offset(0, 3),
//                                             ),
//                                           ]
//                                           : null,
//                                 ),
//                                 child:
//                                     _isDrawing && _cachedSignature != null
//                                         ? Image.memory(
//                                           _cachedSignature!,
//                                           width: _signatureWidth,
//                                           height: _signatureHeight,
//                                         )
//                                         : _signatureImage != null
//                                         ? Image.memory(
//                                           _signatureImage!,
//                                           width: _signatureWidth,
//                                           height: _signatureHeight,
//                                         )
//                                         : const SizedBox.shrink(),
//                               ),
//                             ),
//                           ),
//                         Positioned(
//                           right: 8,
//                           bottom: MediaQuery.of(context).size.height * 0.1,
//                           child: CircularAddButton(
//                             onPressed: _signPdf,
//                             icon: Icons.sign_language,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Signature Drawing Area
//                   Container(
//                     height: 120,
//                     color: Colors.grey[200],
//                     child:
//                         _isDrawing
//                             ? Signature(
//                               controller: _controller,
//                               backgroundColor: Colors.grey[200]!,
//                             )
//                             : _signatureImage != null
//                             ? Image.memory(
//                               _signatureImage!,
//                               height: 120,
//                               width: double.infinity,
//                               fit: BoxFit.contain,
//                             )
//                             : const Center(
//                               child: Text('No signature uploaded'),
//                             ),
//                   ),
//                   // Controls
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primaryColor,
//                             shape: BeveledRectangleBorder(
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                           ),
//                           onPressed: _startDrawing,
//                           child: const Text(
//                             'Draw Signature',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.accentColor,
//                             shape: BeveledRectangleBorder(
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                           ),
//                           onPressed: _uploadSignature,
//                           child: const Text(
//                             'Upload Signature',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }
// }

class _ESignScreenState extends ConsumerState<ESignScreen> {
  final Logger log = Logger();
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final List<List<Point>> _drawingHistory = [];
  Uint8List? _signatureImage;
  Uint8List? _cachedSignature;
  bool _isDrawing = false; // Changed to false initially
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

  // New variables for corner-based resizing
  bool _isTopLeftResizing = false;
  bool _isTopRightResizing = false;
  bool _isBottomLeftResizing = false;
  bool _isBottomRightResizing = false;
  Offset _initialFocalPoint = Offset.zero;

  @override
  void initState() {
    Future<void> initializeDocument() async {
      try {
        final pdfFile = File(widget.pdfPath);
        _document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
        setState(() {
          _isLoading = false;
        });
      } catch (err) {
        log.e('Error initializing PDF document: $err');
        GlobalScaffold.showSnackbar(
          message: 'Error loading PDF: $err',
          backgroundColor: Colors.red,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }

    _controller.onDrawEnd = () async {
      if (_controller.points.isNotEmpty && _isDrawing) {
        // Added _isDrawing check
        _drawingHistory.add(List.from(_controller.points));
        _cachedSignature = await _controller.toPngBytes();
        setState(() {});
      }
    };

    initializeDocument();
    super.initState();
  }

  // ... (keep existing dispose, _uploadSignature, _undoDrawing methods)

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _signatureImage = null;
      _signatureWidth = 150;
      _signatureHeight = 50;
      _initialSignatureWidth = 150;
      _initialSignatureHeight = 50;
      _cachedSignature = null;
      _controller.clear();
      _drawingHistory.clear();
      log.i('Drawing started: _isDrawing=$_isDrawing');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _uploadSignature() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path != null) {
        final bytes = await File(file.path!).readAsBytes();
        setState(() {
          _signatureImage = bytes;
          _isDrawing = false;
          // Reset size for uploaded image
          _signatureWidth = 150;
          _signatureHeight = 50;
          _initialSignatureWidth = 150;
          _initialSignatureHeight = 50;
          _cachedSignature = null;
        });
      }
    } catch (err) {
      log.e('Error uploading signature: $err');
      GlobalScaffold.showSnackbar(
        message: 'Error Uploading Signature: $err',
        backgroundColor: Colors.red,
      );
    }
  }

  void _undoDrawing() {
    setState(() {
      log.i('Drawing history length: ${_drawingHistory.length}');
      if (_drawingHistory.isNotEmpty) {
        _drawingHistory.removeLast();
        if (_drawingHistory.isNotEmpty) {
          _controller.points = List.from(_drawingHistory.last);
          _cachedSignature = null;
        } else {
          _controller.clear();
          _cachedSignature = null;
        }
      } else {
        _controller.clear();
        _cachedSignature = null;
      }
    });
  }

  // New method to handle corner-based resizing
  void _handleResizeStart(Offset localPosition, Size signatureSize) {
    final cornerSize = 20.0;
    final topLeftRect = Rect.fromLTWH(0, 0, cornerSize, cornerSize);
    final topRightRect = Rect.fromLTWH(
      signatureSize.width - cornerSize,
      0,
      cornerSize,
      cornerSize,
    );
    final bottomLeftRect = Rect.fromLTWH(
      0,
      signatureSize.height - cornerSize,
      cornerSize,
      cornerSize,
    );
    final bottomRightRect = Rect.fromLTWH(
      signatureSize.width - cornerSize,
      signatureSize.height - cornerSize,
      cornerSize,
      cornerSize,
    );

    if (topLeftRect.contains(localPosition)) {
      _isTopLeftResizing = true;
    } else if (topRightRect.contains(localPosition)) {
      _isTopRightResizing = true;
    } else if (bottomLeftRect.contains(localPosition)) {
      _isBottomLeftResizing = true;
    } else if (bottomRightRect.contains(localPosition)) {
      _isBottomRightResizing = true;
    }

    _initialFocalPoint = localPosition;
    _initialSignatureWidth = _signatureWidth;
    _initialSignatureHeight = _signatureHeight;
  }

  void _handleResizeUpdate(Offset localPosition) {
    final delta = localPosition - _initialFocalPoint;

    if (_isTopLeftResizing) {
      final newWidth = _initialSignatureWidth - delta.dx;
      final newHeight = _initialSignatureHeight - delta.dy;
      setState(() {
        _signatureWidth = newWidth.clamp(50, 300);
        _signatureHeight = newHeight.clamp(20, 150);
        _signaturePosition = _signaturePosition + Offset(delta.dx, delta.dy);
      });
    } else if (_isTopRightResizing) {
      final newWidth = _initialSignatureWidth + delta.dx;
      final newHeight = _initialSignatureHeight - delta.dy;
      setState(() {
        _signatureWidth = newWidth.clamp(50, 300);
        _signatureHeight = newHeight.clamp(20, 150);
        _signaturePosition = _signaturePosition + Offset(0, delta.dy);
      });
    } else if (_isBottomLeftResizing) {
      final newWidth = _initialSignatureWidth - delta.dx;
      final newHeight = _initialSignatureHeight + delta.dy;
      setState(() {
        _signatureWidth = newWidth.clamp(50, 300);
        _signatureHeight = newHeight.clamp(20, 150);
        _signaturePosition = _signaturePosition + Offset(delta.dx, 0);
      });
    } else if (_isBottomRightResizing) {
      final newWidth = _initialSignatureWidth + delta.dx;
      final newHeight = _initialSignatureHeight + delta.dy;
      setState(() {
        _signatureWidth = newWidth.clamp(50, 300);
        _signatureHeight = newHeight.clamp(20, 150);
      });
    }
  }

  void _handleResizeEnd() {
    _isTopLeftResizing = false;
    _isTopRightResizing = false;
    _isBottomLeftResizing = false;
    _isBottomRightResizing = false;
  }

  void _toggleMode() {
    setState(() {
      _resizeMode = !_resizeMode;
      log.i('Mode toggled to: ${_resizeMode ? 'Resize' : 'Drag'}');
    });
  }

  Future<void> _signPdf() async {
    try {
      if (_isDrawing) {
        if (_controller.isEmpty) {
          GlobalScaffold.showSnackbar(
            message: 'Please draw a signature',
            backgroundColor: Colors.amber,
          );
          return;
        }
        _signatureImage = await _controller.toPngBytes();
      }

      if (_signatureImage == null) {
        GlobalScaffold.showSnackbar(
          message: 'No Signature Provided',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Ensure the current page exists
      if (_currentPage < 1 || _currentPage > _document.pages.count) {
        GlobalScaffold.showSnackbar(
          message: 'Invalid page number',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Add the signature to the specified page
      final page = _document.pages[_currentPage - 1];
      final pdfPageWidth = page.getClientSize().width;
      final pdfPageHeight = page.getClientSize().height;

      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight =
          MediaQuery.of(context).size.height - kToolbarHeight - 200 - 16;

      final pdfAspectRatio = pdfPageWidth / pdfPageHeight;
      final screenAspectRatio = screenWidth / screenHeight;

      double scaleFactor;
      double offsetX = 0;
      double offsetY = 0;

      if (pdfAspectRatio > screenAspectRatio) {
        // PDF is wider than the screen: fit by width
        scaleFactor = pdfPageWidth / screenWidth;
        final displayHeight = screenWidth / pdfAspectRatio;
        offsetY = (screenHeight - displayHeight) / 2;
      } else {
        // PDF is taller than the screen: fit by height
        scaleFactor = pdfPageHeight / screenHeight;
        final displayedWidth = screenHeight * pdfAspectRatio;
        offsetX = (screenWidth - displayedWidth) / 2;
      }

      final pdfX = (_signaturePosition.dx - offsetX) * scaleFactor;
      final pdfY = (_signaturePosition.dy - offsetY) * scaleFactor;
      final pdfWidth = _signatureWidth * scaleFactor;
      final pdfHeight = _signatureHeight * scaleFactor;

      log.i(
        'Screen position: ${_signaturePosition.dx}, ${_signaturePosition.dy}',
      );
      log.i('PDF position: $pdfX, $pdfY');
      log.i('PDF page size: $pdfPageWidth x $pdfPageHeight');
      log.i('Scaled size: $pdfWidth x $pdfHeight');

      final finalX = pdfX.clamp(0, pdfPageWidth - pdfWidth);
      final finalY = pdfY.clamp(0, pdfPageHeight - pdfHeight);

      final PdfBitmap signatureBitmap = PdfBitmap(_signatureImage!);
      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          finalX.toDouble(),
          finalY.toDouble(),
          pdfWidth,
          pdfHeight,
        ),
      );

      // Save the updated PDF
      final directory = await getApplicationSupportDirectory();
      final signedPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signedFile = File(signedPath);
      await signedFile.writeAsBytes(await _document.save());

      // Update the state
      ref.read(pdfStateProvider.notifier).setPdfPath([signedPath]);
      ref.read(pdfStateProvider.notifier).state = ref
          .read(pdfStateProvider)
          .copyWith(selectedPdfs: {signedPath});

      context.pop();
      GlobalScaffold.showSnackbar(
        message: 'PDF Signed Successfully',
        backgroundColor: AppColors.accentColor,
      );
    } catch (err) {
      log.e('Error signing PDF: $err');
      GlobalScaffold.showSnackbar(message: 'Error signing PDF: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _toggleMode,
            icon: Icon(
              _resizeMode ? Icons.zoom_out_map : Icons.drag_handle,
              color:
                  _resizeMode ? AppColors.accentColor : AppColors.primaryColor,
            ),
            tooltip: _resizeMode ? 'Switch to Drag' : 'Switch to Resize',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // PDF Preview with Draggable and Resizable Signature
                  Expanded(
                    child: Stack(
                      children: [
                        SfPdfViewer.file(
                          File(widget.pdfPath),
                          initialPageNumber: _currentPage,
                          onPageChanged: (details) {
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                          },
                        ),
                        if (_signatureImage != null ||
                            (_isDrawing && _controller.points.isNotEmpty))
                          Positioned(
                            left: _signaturePosition.dx,
                            top: _signaturePosition.dy,
                            child: GestureDetector(
                              onScaleStart: (details) {
                                if (_resizeMode) {
                                  _handleResizeStart(
                                    details.localFocalPoint,
                                    Size(_signatureWidth, _signatureHeight),
                                  );
                                } else {
                                  setState(() {
                                    _isInteracting = true;
                                  });
                                }
                              },
                              onScaleUpdate: (details) {
                                if (_resizeMode &&
                                    (_isTopLeftResizing ||
                                        _isTopRightResizing ||
                                        _isBottomLeftResizing ||
                                        _isBottomRightResizing)) {
                                  _handleResizeUpdate(details.localFocalPoint);
                                } else if (!_resizeMode) {
                                  setState(() {
                                    _signaturePosition +=
                                        details.focalPointDelta;
                                    _signaturePosition = Offset(
                                      _signaturePosition.dx.clamp(
                                        0,
                                        MediaQuery.of(context).size.width -
                                            _signatureWidth,
                                      ),
                                      _signaturePosition.dy.clamp(
                                        0,
                                        MediaQuery.of(context).size.height -
                                            _signatureHeight -
                                            kToolbarHeight,
                                      ),
                                    );
                                  });
                                }
                              },
                              onScaleEnd: (_) {
                                setState(() {
                                  _isInteracting = false;
                                });
                                _handleResizeEnd();
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border:
                                          _isInteracting
                                              ? Border.all(
                                                color:
                                                    _resizeMode
                                                        ? Colors.green
                                                        : Colors.blue,
                                                width: 2,
                                              )
                                              : null,
                                      boxShadow:
                                          _isInteracting
                                              ? [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child:
                                        _isDrawing && _cachedSignature != null
                                            ? Image.memory(
                                              _cachedSignature!,
                                              width: _signatureWidth,
                                              height: _signatureHeight,
                                            )
                                            : _signatureImage != null
                                            ? Image.memory(
                                              _signatureImage!,
                                              width: _signatureWidth,
                                              height: _signatureHeight,
                                            )
                                            : const SizedBox.shrink(),
                                  ),
                                  if (_resizeMode) ..._buildResizeHandles(),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          right: 8,
                          bottom: MediaQuery.of(context).size.height * 0.1,
                          child: CircularAddButton(
                            onPressed: _signPdf,
                            icon: Icons.sign_language,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Signature Drawing Area
                  Container(
                    height: 120,
                    color: Colors.grey[200],
                    child:
                        _isDrawing
                            ? Signature(
                              controller: _controller,
                              backgroundColor: Colors.grey[200]!,
                            )
                            : _signatureImage != null
                            ? Image.memory(
                              _signatureImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            )
                            : const Center(
                              child: Text('No signature uploaded'),
                            ),
                  ),
                  // Controls
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
                          onPressed: _uploadSignature,
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

  List<Widget> _buildResizeHandles() {
    const handleSize = 20.0;
    const handleColor = Colors.blue;

    return [
      // Top-left handle
      Positioned(
        left: 0,
        top: 0,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isTopLeftResizing = true;
              _initialFocalPoint = details.localPosition;
              _initialSignatureWidth = _signatureWidth;
              _initialSignatureHeight = _signatureHeight;
            });
          },
          onPanUpdate: (details) {
            _handleResizeUpdate(details.localPosition);
          },
          onPanEnd: (_) {
            _handleResizeEnd();
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
              ),
            ),
          ),
        ),
      ),
      // Top-right handle
      Positioned(
        right: 0,
        top: 0,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isTopRightResizing = true;
              _initialFocalPoint = details.localPosition;
              _initialSignatureWidth = _signatureWidth;
              _initialSignatureHeight = _signatureHeight;
            });
          },
          onPanUpdate: (details) {
            _handleResizeUpdate(details.localPosition);
          },
          onPanEnd: (_) {
            _handleResizeEnd();
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      ),
      // Bottom-left handle
      Positioned(
        left: 0,
        bottom: 0,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isBottomLeftResizing = true;
              _initialFocalPoint = details.localPosition;
              _initialSignatureWidth = _signatureWidth;
              _initialSignatureHeight = _signatureHeight;
            });
          },
          onPanUpdate: (details) {
            _handleResizeUpdate(details.localPosition);
          },
          onPanEnd: (_) {
            _handleResizeEnd();
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
        ),
      ),
      // Bottom-right handle
      Positioned(
        right: 0,
        bottom: 0,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isBottomRightResizing = true;
              _initialFocalPoint = details.localPosition;
              _initialSignatureWidth = _signatureWidth;
              _initialSignatureHeight = _signatureHeight;
            });
          },
          onPanUpdate: (details) {
            _handleResizeUpdate(details.localPosition);
          },
          onPanEnd: (_) {
            _handleResizeEnd();
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
