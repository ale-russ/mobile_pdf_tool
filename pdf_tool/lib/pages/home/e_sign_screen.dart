import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_tool/providers/pdf_state_provider.dart';
import 'package:pdf_tool/widgets/add_button.dart';
import 'package:pdf_tool/widgets/submit_button.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../utils/app_colors.dart';
import '../../utils/helper_methods.dart';
import '../../utils/scaffold_uitiltiy.dart';

class ESignScreen extends ConsumerStatefulWidget {
  const ESignScreen({super.key, this.pdfPath});
  final String? pdfPath;

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

  Uint8List? _signatureImage;
  bool _isDrawing = true;
  double _signatureX = 50;
  double _signatureY = 50;
  double _signatureWidth = 150;
  double _signatureHeight = 50;
  int _currentPage = 1;

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

      // Load the PDF
      final pdfFile = File(widget.pdfPath!);
      final document = PdfDocument(inputBytes: await pdfFile.readAsBytes());

      // Ensure the current page exists
      if (_currentPage < 1 || _currentPage > document.pages.count) {
        GlobalScaffold.showSnackbar(
          message: 'Invalid page number',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Add the signature to the specified page
      final page = document.pages[_currentPage - 1];
      final PdfBitmap signatureBitmap = PdfBitmap(_signatureImage!);
      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          _signatureX,
          _signatureY,
          _signatureWidth,
          _signatureHeight,
        ),
      );

      // save the updated PDF
      // HelperMethods.fileSave(await pdfFile.readAsBytes());
      final directory = await getApplicationSupportDirectory();
      final signedPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signedFile = File(signedPath);
      await signedFile.writeAsBytes(await document.save());
      document.dispose();

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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child:
              widget.pdfPath == null || widget.pdfPath!.isEmpty
                  ? Container(
                    color: Colors.green,

                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            "No File Loaded",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                        Spacer(flex: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AddButton(),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                'Page: $_currentPage',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                      setState(() {
                                        _currentPage++;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_forward),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _isDrawing
                                  ? Signature(
                                    controller: _controller,
                                    height: 200,
                                    backgroundColor: Colors.grey[200]!,
                                  )
                                  : _signatureImage != null
                                  ? Image.memory(
                                    _signatureImage!,
                                    width: 200,
                                    height: 200,
                                  )
                                  : const Text('No signature uploaded'),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: BeveledRectangleBorder(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isDrawing = true;
                                        _signatureImage = null;
                                      });
                                      _controller.clear();
                                    },
                                    child: Text(
                                      "Draw Signature",
                                      style: TextStyle(color: AppColors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentColor,
                                      shape: BeveledRectangleBorder(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    onPressed: _uploadSignature,
                                    child: Text(
                                      "Upload Signature",
                                      style: TextStyle(color: AppColors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Adjust Signature Position and Size",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                height: 200,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    const Text('Horizontal Position'),
                                    Expanded(
                                      child: Slider(
                                        value: _signatureX,
                                        min: 0,
                                        max: 500,
                                        onChanged:
                                            (value) => setState(
                                              () => _signatureX = value,
                                            ),
                                      ),
                                    ),
                                    Text("${_signatureX.toInt()}"),
                                    Row(
                                      children: [
                                        const Text("Vertical Position"),
                                        Expanded(
                                          child: Slider(
                                            value: _signatureY,
                                            min: 0,
                                            max: 700,
                                            onChanged:
                                                (value) => setState(
                                                  () => _signatureY = value,
                                                ),
                                          ),
                                        ),
                                        Text('${_signatureY.toInt()}'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('Width: '),
                                        Expanded(
                                          child: Slider(
                                            value: _signatureWidth,
                                            min: 50,
                                            max: 300,
                                            onChanged: (value) {
                                              setState(
                                                () => _signatureWidth = value,
                                              );
                                            },
                                          ),
                                        ),
                                        Text('${_signatureWidth.toInt()}'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('Height: '),
                                        Expanded(
                                          child: Slider(
                                            value: _signatureHeight,
                                            min: 20,
                                            max: 150,
                                            onChanged: (value) {
                                              setState(
                                                () => _signatureHeight = value,
                                              );
                                            },
                                          ),
                                        ),
                                        Text('${_signatureHeight.toInt()}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SubmitButton(
                          title: 'Sign PDF',
                          onPressed: _signPdf,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
