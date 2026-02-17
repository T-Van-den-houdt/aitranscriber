import 'package:aitranscribe/core/constants.dart';
import 'package:aitranscribe/services/ocr_service.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart';

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  bool isModelReady = false;
  InferenceModel? _model;

  Future<void> init() async {
    if (isModelReady) return;

    if (!FlutterGemma.hasActiveModel()) {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            AppConstants.modelUrlVision,
            token: AppConstants.hfToken,
          )
          .withProgress((p) => downloadProgress.value = p / 100)
          .install();

      debugPrint("Installed model: ${AppConstants.modelUrlVision}");
    }

    _model = await FlutterGemma.getActiveModel(
      maxTokens: 1024,
      preferredBackend: PreferredBackend.gpu,
    );

    isModelReady = true;
    downloadProgress.value = 1.0;
  }

  Stream<String> toJsonStream(List<OcrLine> lines) async* {
    if (!isModelReady) await init();

    final chat = await _model!.createChat(
      temperature: 1.0,
      topK: 64,
      topP: 0.95,
    );

    final formattedText =
        lines.map((l) => "${l.text} [${l.x},${l.y}]").join(' | ');

    final prompt = """
Extraheer gegevens uit onderstaande tekst.
Geef alleen geldige JSON. Geen uitleg.

Input:
$formattedText

Output:
{"serienummer":"...","bouwjaar":"...","merk":"..."}
""";

    await chat.addQuery(Message.text(text: prompt));

    String accumulated = "";
    String lastChunk = "";
    int repeatCount = 0;

    await for (final chunk in chat.generateChatResponseAsync()) {
      String raw = chunk
          .toString()
          .replaceAll(RegExp(r'```json|```'), '')
          .trim();

      if (raw == lastChunk) {
        repeatCount++;
        if (repeatCount > 5) break;
      } else {
        repeatCount = 0;
      }

      lastChunk = raw;
      accumulated += raw;

      if (accumulated.contains('}')) {
        accumulated = accumulated.substring(
          0,
          accumulated.indexOf('}') + 1,
        );
        yield accumulated;
        break;
      }

      yield accumulated;
    }
  }
}
