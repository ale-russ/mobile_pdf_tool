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
  ConsumerState<ConsumerStatefulWidget> createState() => _ESignScreenState();
}

class _ESignScreenState extends ConsumerState<ESignScreen> {
  final Logger log = Logger();
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  final List<List<Point>> _drawingHistory = [];
  Uint8List? _signatureImage;
  bool _isDrawing = true;
  Offset _signaturePosition = const Offset(50, 50);
  final double _signatureWidth = 150;
  final double _signatureHeight = 50;
  int _currentPage = 1;
  late final PdfDocument _document;
  bool _isDragging = false;

  @override
  initState() {
    Future<void> initializeDocument() async {
      final pdfFile = File(widget.pdfPath);
      _document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
    }

    // _controller.addListener(() {
    //   if (_controller.points.isNotEmpty) {
    //     _drawingHistory.add(List.from(_controller.points));
    //   }
    // });

    _controller.onDrawEnd = () {
      if (_controller.points.isEmpty) {
        _drawingHistory.add(List.from(_controller.points));
      }
    };

    initializeDocument();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        });
      }
    } catch (err) {
      log.e('Error uploading signature: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Uploading Signature : $err")),
      );
    }
  }

  void _undoDrawing() {
    // if (_drawingHistory.isNotEmpty) {
    //   _drawingHistory.removeLast();
    //   _controller.points = _drawingHistory.expand((e) => e).toList();
    // } else {
    //   _controller.clear();
    // }
    setState(() {
      log.i('drawing history: ${_drawingHistory.length}');
      if (_drawingHistory.isNotEmpty) {
        log.i('in if clause');
        _drawingHistory.removeLast();
        _controller.points = _drawingHistory.expand((e) => e).toList();
      } else {
        log.i('in else if clause');
        _controller.clear();
      }
      // _isDrawing = true;
      // _signatureImage = null;
    });
    // _controller.clear();
    // _drawingHistory.clear();
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
          MediaQuery.of(context).size.height - kToolbarHeight - 200;

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
        // Pdf is taller than the screen: fit by height
        scaleFactor = pdfPageHeight / screenHeight;
        final displayedWidth = screenHeight * pdfAspectRatio;
        offsetX = (screenWidth - displayedWidth) / 2;
      }

      final pdfX = (_signaturePosition.dx - offsetX) * scaleFactor;
      final pdfY = (_signaturePosition.dy - offsetX) * scaleFactor;
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

      // save the updated PDF
      // HelperMethods.fileSave(await pdfFile.readAsBytes());
      final directory = await getApplicationSupportDirectory();
      final signedPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signedFile = File(signedPath);
      await signedFile.writeAsBytes(await _document.save());
      _document.dispose();

      // update the state
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
        actions: [IconButton(onPressed: _undoDrawing, icon: Icon(Icons.undo))],
      ),
      body: Column(
        children: [
          Text(
            'Page: $_currentPage/${_document.pages.count}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_currentPage > 1) _currentPage--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                onPressed: () {
                  if (_currentPage < _document.pages.count) {
                    setState(() {
                      _currentPage++;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          // PDF Preview with Draggable Signature
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
                      onPanStart: (_) {
                        setState(() => _isDragging = true);
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _signaturePosition += details.delta;
                          // Keep the signature within bounds
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
                      },
                      onPanEnd: (_) {
                        setState(() => _isDragging = false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border:
                              _isDragging
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                        ),
                        child:
                            _isDrawing
                                ? FutureBuilder<Uint8List?>(
                                  future: _controller.toPngBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: _signatureWidth,
                                        height: _signatureHeight,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                )
                                : Image.memory(
                                  _signatureImage!,
                                  width: _signatureWidth,
                                  height: _signatureHeight,
                                ),
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
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                    : const Center(child: Text('No signature uploaded')),
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
                  onPressed: () {
                    if (_drawingHistory.isNotEmpty) {
                      setState(() {
                        _drawingHistory.removeLast();
                        if (_drawingHistory.isNotEmpty) {
                          _controller.points = List.from(_drawingHistory.last);
                        } else {
                          _controller.clear();
                        }
                      });
                    }
                  },
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
