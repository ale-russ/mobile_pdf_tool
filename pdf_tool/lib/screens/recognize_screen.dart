import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecognizeScreen extends ConsumerStatefulWidget {
  RecognizeScreen({super.key, this.image});

  File? image;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RecognizeScreenState();
}

class _RecognizeScreenState extends ConsumerState<RecognizeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
