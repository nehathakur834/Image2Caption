import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/caption_provider.dart';
import 'screens/app_shell.dart';
import 'services/ai_caption_service.dart';
import 'services/image_picker_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // It's fine if no .env file exists; we still support --dart-define.
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
      child: const AiCaptionGeneratorApp(),
    ),
  );
}

class AiCaptionGeneratorApp extends StatelessWidget {
  const AiCaptionGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Caption Generator App',
      themeMode: provider.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const AppShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final seedColor = brightness == Brightness.dark
        ? const Color(0xFF8BD8BD)
        : const Color(0xFF0E7C86);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF08131A)
          : const Color(0xFFF4F7FB),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF10202A)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF132834)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}
