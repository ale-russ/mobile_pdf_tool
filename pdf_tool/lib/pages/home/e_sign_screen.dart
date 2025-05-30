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
  final GlobalKey _pdfViewerKey = GlobalKey();
  PdfViewerController? pdfViewerController = PdfViewerController();
  final Logger log = Logger();
  late final ESignUtils _helper;

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

  @override
  void initState() {
    _helper = ESignUtils();
    Future<void> initializeDocument() async {
      setState(() {
        _isLoading = true;
      });
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

    _helper.controller.onDrawEnd = () async {
      if (_helper.controller.points.isNotEmpty) {
        // Ensure points exist before adding
        _drawingHistory.add(List.from(_helper.controller.points));
        _cachedSignature = await _helper.controller.toPngBytes();
        setState(() {});
      }
    };

    initializeDocument();
    super.initState();
  }

  @override
  void dispose() {
    _helper.controller.dispose();
    _document.dispose();
    pdfViewerController?.dispose();
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
          _helper.controller.points = List.from(_drawingHistory.last);
          _cachedSignature = null;
        } else {
          _helper.controller.clear();
          _cachedSignature = null;
        }
      } else {
        _helper.controller.clear();
        _cachedSignature = null;
      }
    });
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _signatureImage = null;
      _signatureWidth = 150;
      _signatureHeight = 50;
      _initialSignatureWidth = 150;
      _initialSignatureHeight = 50;
      _cachedSignature = null;
      _helper.controller.clear();
      _drawingHistory.clear();
      log.i('Drawing started: _isDrawing=$_isDrawing');
    });
  }

  Future<void> _signPdf() async {
    try {
      if (_isDrawing) {
        if (_helper.controller.isEmpty) {
          GlobalScaffold.showSnackbar(
            message: 'Please draw a signature',
            backgroundColor: Colors.amber,
          );
          return;
        }
        _signatureImage = await _helper.controller.toPngBytes();
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

      // Get the PDF page dimensions
      final page = _document.pages[_currentPage - 1];
      final pdfPageSize = page.getClientSize();
      final pdfPageWidth = pdfPageSize.width;
      final pdfPageHeight = pdfPageSize.height;

      // Get the PDF viewer's render box to calculate the actual displayed size
      final viewerKey = GlobalKey();
      final renderBox =
          _pdfViewerKey.currentContext?.findRenderObject() as RenderBox?;
      // final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        log.e('renderBox is null');
        return;
      }

      // Calculate the scale and offset of the PDF in the viewer
      final viewerSize = renderBox.size;
      final viewerOffset = renderBox.localToGlobal(Offset.zero);
      final pdfAspectRatio = pdfPageWidth / pdfPageHeight;
      final viewerAspectRatio = viewerSize.width / viewerSize.height;

      double scale;
      Offset pdfOffset = Offset.zero;
      double offsetX = 0;
      double offsetY = 0;

      if (pdfAspectRatio > viewerAspectRatio) {
        // PDF is wider than viewer - fit to width
        scale = viewerSize.width / pdfPageWidth;
        final displayedHeight = pdfPageHeight * scale;
        // offsetY = (viewerSize.height - displayedHeight) / 2;
        pdfOffset = Offset(0, (viewerSize.height - displayedHeight) / 2);
      } else {
        // PDF is taller than viewer - fit to height
        scale = viewerSize.height / pdfPageHeight;
        final displayedWidth = pdfPageWidth * scale;
        // offsetX = (viewerSize.width - displayedWidth) / 2;
        pdfOffset = Offset((viewerSize.width - displayedWidth) / 2, 0);
      }

      // Convert screen coordinates to PDF coordinates
      // first adjust for the viewer's position on screen
      final relativeSignaturePosition = _signaturePosition - viewerOffset;
      final pdfX = (relativeSignaturePosition.dx - pdfOffset.dx) / scale;
      final pdfY = (relativeSignaturePosition.dy - pdfOffset.dy) / scale;
      // final pdfX = (_signaturePosition.dx - offsetX) / scale;
      // final pdfY = (_signaturePosition.dy - offsetY) / scale;
      final pdfWidth = _signatureWidth / scale;
      final pdfHeight = _signatureHeight / scale;

      // Ensure the signature stays within page bounds
      final clampedX = pdfX.clamp(0, pdfPageWidth - pdfWidth);
      final clampedY = pdfY.clamp(0, pdfPageHeight - pdfHeight);

      log.i('''
      Screen position: ${_signaturePosition.dx}, ${_signaturePosition.dy}
      PDF position: $clampedX, $clampedY
      PDF page size: $pdfPageWidth x $pdfPageHeight
      Signature size: $pdfWidth x $pdfHeight
      Scale factor: $scale
      Viewer offset: $offsetX, $offsetY
    ''');

      // Draw the signature on the PDF
      final PdfBitmap signatureBitmap = PdfBitmap(_signatureImage!);
      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          clampedX.toDouble(),
          clampedY.toDouble(),
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

  void _toggleMode() {
    setState(() {
      _resizeMode = !_resizeMode;
      log.i('Mode toggled to: ${_resizeMode ? 'Resize' : 'Drag'}');
    });
  }

  @override
  Widget build(BuildContext context) {
    log.i('isDrawing: $_isDrawing');
    log.i('signatureImage: $_signatureImage');
    log.i(
      'Dual conditions: ${(_isDrawing && _helper.controller.points.isNotEmpty)}',
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
                          key: _pdfViewerKey,
                          // controller: pdfViewerController!,
                          onPageChanged: (details) {
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                          },
                        ),
                        if (_signatureImage != null ||
                            (_isDrawing &&
                                _helper.controller.points.isNotEmpty))
                          Positioned(
                            left: _signaturePosition.dx,
                            top: _signaturePosition.dy,
                            child: GestureDetector(
                              onScaleStart: (details) {
                                setState(() {
                                  _isInteracting = true;
                                  _isResizing = false;
                                  _initialScale = 1.0;
                                  _initialSignatureWidth = _signatureWidth;
                                  _initialSignatureHeight = _signatureHeight;
                                });
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  // Handle dragging or resizing based on mode
                                  if (!_resizeMode || details.scale == 1.0) {
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
                                  }
                                  if (_resizeMode && details.scale != 1.0) {
                                    _isResizing = true;
                                    double newScale =
                                        details.scale * _initialScale;
                                    _signatureWidth = (_initialSignatureWidth *
                                            newScale)
                                        .clamp(50, 300);
                                    _signatureHeight =
                                        (_initialSignatureHeight * newScale)
                                            .clamp(20, 150);
                                    _signaturePosition = Offset(
                                      _signaturePosition.dx -
                                          (_signatureWidth -
                                                  _initialSignatureWidth *
                                                      newScale) /
                                              2,
                                      _signaturePosition.dy -
                                          (_signatureHeight -
                                                  _initialSignatureHeight *
                                                      newScale) /
                                              2,
                                    );
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
                                  }
                                });
                              },
                              onScaleEnd: (_) {
                                setState(() {
                                  _isInteracting = false;
                                  _isResizing = false;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      _isInteracting
                                          ? Border.all(
                                            color:
                                                _isResizing
                                                    ? Colors.green
                                                    : Colors.blue,
                                            width: 2,
                                          )
                                          : null,
                                  boxShadow:
                                      _isInteracting
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
                              controller: _helper.controller,
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
}
