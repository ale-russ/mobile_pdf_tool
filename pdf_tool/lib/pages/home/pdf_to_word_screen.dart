import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfToWordScreen extends ConsumerStatefulWidget {
  const PdfToWordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PdfToWordState();
}

class _PdfToWordState extends ConsumerState<PdfToWordScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('PDF to Word')));
  }
}
