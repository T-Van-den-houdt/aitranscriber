import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLine {
  final String text;
  final Rect boundingBox;
  final int x;
  final int y;
  final double confidence;

  OcrLine(this.text, this.boundingBox, this.confidence)
    : x = boundingBox.left.toInt(),
      y = boundingBox.top.toInt();

  @override
  String toString() {
    final int confPercent = (confidence * 100).toInt();
    return "OcrLine(text: '$text', pos: [$x, $y], confidence: $confPercent%)";
  }
}

class OcrService {
  final _recognizer = TextRecognizer();

  Future<List<OcrLine>> scanFile(String path) async {
    final image = InputImage.fromFile(File(path));
    final result = await _recognizer.processImage(image);

    return result.blocks.expand((block) {
      return block.lines.map((line) {
        return OcrLine(line.text, line.boundingBox, line.confidence ?? 0.0);
      });
    }).toList();
  }

  void dispose() => _recognizer.close();
}
