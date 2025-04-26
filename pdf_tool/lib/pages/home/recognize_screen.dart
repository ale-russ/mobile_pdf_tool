// ignore_for_file: unused_local_variable

import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../utils/app_colors.dart';

// ignore: must_be_immutable
class RecognizeScreen extends ConsumerStatefulWidget {
  RecognizeScreen({super.key, this.image});

  File? image;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RecognizeScreenState();
}

class _RecognizeScreenState extends ConsumerState<RecognizeScreen> {
  late TextRecognizer textRecognizer;
  String result = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    recognizeText();
  }

  recognizeText() async {
    final InputImage inputImage = InputImage.fromFile(widget.image!);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    result = recognizedText.text;
    setState(() {});
    developer.log('Text: $result');
    for (TextBlock block in recognizedText.blocks) {
      final Rect rect = block.boundingBox;
      final List<Point<int>> cornerPoints = block.cornerPoints;
      final String text = block.text;
      final List<String> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: TColor.primary,
        centerTitle: true,
        title: Text('Recognizer', style: TextStyle(color: TColor.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(widget.image!),
            const SizedBox(height: 20),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: TColor.primary,
                border: Border.all(color: TColor.borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Results',
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.copy, color: TColor.white),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(result),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
