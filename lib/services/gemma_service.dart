import 'dart:convert';
import 'package:aitranscribe/core/constants.dart';
import 'package:aitranscribe/services/ocr_service.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart';
import 'package:aitranscribe/constants.dart';

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  bool isModelReady = false;
  InferenceModel? _model;
  InferenceChat? _persistentChat; // Keep one chat alive

  // Call this in main() to start loading in the background
  Future<void> init() async {
    if (isModelReady) return;

    // 1. Check/Install Model
    if (!FlutterGemma.hasActiveModel()) {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            AppConstants.modelUrlVision,
            token: AppConstants.hfToken,
          )
          .withProgress((p) => downloadProgress.value = p / 100)
          .install();
          debugPrint("Installed model: $AppConstants.modelUrlVision");
    }

    // 2. Pre-warm: Load model into memory
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 512, // Lower maxTokens = faster response
      preferredBackend: PreferredBackend.gpu, // Use GPU for 2-5x speed
    );

    // 3. Pre-warm: Initialize the chat session
    _persistentChat = await _model!.createChat();
    
    isModelReady = true;
    downloadProgress.value = 1.0;
  }

  Stream<String> toJsonStream(List<OcrLine> lines) async* {
    if (!isModelReady) await init();

    // Reset history so coordinates from previous scans don't confuse the model
    await _persistentChat!.clearHistory();

    // Use a compact prompt format to reduce token processing time
    final formattedText = lines.map((l) => "${l.text} [${l.x},${l.y}]").join(' | ');

    final prompt = """
Extract to JSON (Dutch). Fields: serienummer, bouwjaar, merk.
Use [x,y] for layout. Output ONLY JSON.
Tekst: $formattedText
""";

    await _persistentChat!.addQueryChunk(Message.text(text: prompt, isUser: true));

    String accumulated = "";
    await for (final chunk in _persistentChat!.generateChatResponseAsync()) {
      // Clean up markdown markers if the model includes them
      String raw = chunk.toString().replaceAll(RegExp(r'```json|```'), '').trim();
      accumulated += raw;
      yield accumulated;
    }
  }
}