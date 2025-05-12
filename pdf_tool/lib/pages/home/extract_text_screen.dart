import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../providers/pdf_state_provider.dart';
import '../../utils/helper_methods.dart';
import '../../widgets/submit_button.dart';

class ExtractTextScreen extends ConsumerStatefulWidget {
  const ExtractTextScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ExtractTextScreenState();
}

class _ExtractTextScreenState extends ConsumerState<ExtractTextScreen> {
  final Logger log = Logger();
  bool isLoading = false;
  String? extractedText;

  @override
  void initState() {
    super.initState();
  }

  Future<void> extractTextFromImage() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No Image Selected"),
          ),
        );
        return;
      }

      final file = result.files.first;

      CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: file.path!,
        //  aspectRatioPresets: [CropAspectRatioPreset.square],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image cropping cancelled")),
        );
        return;
      }

      // if (HelperMethods.maxFileSizeForFrontend <= file.size) {
      // Process the image for better OCR
      final img.Image? processedImage = await _preprocessImage(
        croppedImage.path,
      );

      if (processedImage == null) {
        throw Exception("Failed to process Image");
      }

      // Convert processed image to InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(croppedImage.path);

      // Initialize TextRecognizer
      final textReconizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textReconizer.processImage(
        inputImage,
      );

      // Extract Text
      final text = recognizedText.text;
      log.i('Extracted text: $text');

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('No Text Detected In The Image'),
          ),
        );
        return;
      }

      setState(() {
        extractedText = text;
      });

      ref.read(extractTextFromImageProvider.notifier).setExtractedText(text);
      // } else {}
    } catch (err) {
      log.e('Error: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error extracting text: $err"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<img.Image?> _preprocessImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Convert to grayscale and enhance contrast
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.5);

      // Save processed image temporarily (optional, For ML kit input)
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/processed_image.jpg';
      await File(tempPath).writeAsBytes(img.encodeJpg(image));
      return image;
    } catch (err) {
      log.e('Error preprocessing image: $err');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Extract Text From Image'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            ref.invalidate(extractTextFromImageProvider);
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0.5,
      ),

      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : extractedText == null || extractedText!.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No Text Extracted',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: 200,
                      height: 70,
                      child: SubmitButton(
                        onPressed: extractTextFromImage,
                        title: "Select File",
                      ),
                    ),
                  ],
                ),
              )
              : Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          extractedText!,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 175,
                          child: SubmitButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: extractedText!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Text copied to clipboard"),
                                ),
                              );
                            },
                            title: "Copy",
                          ),
                        ),
                        SizedBox(
                          width: 175,
                          child: SubmitButton(
                            onPressed: () async {
                              final path = await HelperMethods.fileSave(
                                Uint8List.fromList(extractedText!.codeUnits),
                              );

                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Text saved as File"),
                                  ),
                                );
                              }
                            },
                            title: 'Save',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
