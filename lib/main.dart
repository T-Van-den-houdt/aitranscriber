import 'package:aitranscribe/services/gemma_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  GemmaService().init();

  await SentryFlutter.init(
    (options) => options.dsn = AppConstants.sentryDsn,
    appRunner: () => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    )),
  );
}