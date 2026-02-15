import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
import 'ocr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GemmaService _service = GemmaService();

  @override
  void initState() {
    super.initState();
    _service.init().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Vision Lab")),
      body: ValueListenableBuilder<double>(
        valueListenable: _service.downloadProgress,
        builder: (context, progress, _) {
          final ready = progress >= 1.0;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!ready) LinearProgressIndicator(value: progress),
              const SizedBox(height: 20),
              ListTile(
                tileColor: ready ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                leading: const Icon(Icons.document_scanner),
                title: const Text("Hybrid OCR Scanner"),
                subtitle: Text(ready ? "Gemma 3N Ready" : "Downloading Model..."),
                onTap: ready ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRScreen())) : null,
              ),
            ],
          );
        },
      ),
    );
  }
}