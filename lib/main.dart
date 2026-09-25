import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/caption_provider.dart';
import 'screens/app_shell.dart';
import 'services/ai_caption_service.dart';
import 'services/image_picker_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // Fine if no .env file exists; --dart-define is also supported.
  }

  const apiKeyFromDefine = String.fromEnvironment('OPENAI_API_KEY');
  final apiKey = apiKeyFromDefine.isNotEmpty
      ? apiKeyFromDefine
      : (dotenv.env['OPENAI_API_KEY'] ?? '');

  runApp(
    ChangeNotifierProvider(
      create: (_) => CaptionProvider(
        aiCaptionService: OpenAiCaptionService(apiKey: apiKey),
        imagePickerService: ImagePickerService(),
      )..initialize(),
      child: const Image2CaptionApp(),
    ),
  );
}

class Image2CaptionApp extends StatelessWidget {
  const Image2CaptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image2Caption',
      themeMode: provider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}
