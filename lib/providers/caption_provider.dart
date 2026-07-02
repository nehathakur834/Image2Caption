import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/app_database.dart';
import '../models/caption_record.dart';
import '../models/caption_result.dart';
import '../services/ai_caption_service.dart';
import '../services/image_picker_service.dart';

class CaptionProvider extends ChangeNotifier {
  CaptionProvider({
    required CaptionGenerationService aiCaptionService,
    required ImagePickerService imagePickerService,
  }) : _aiCaptionService = aiCaptionService,
       _imagePickerService = imagePickerService;

  final CaptionGenerationService _aiCaptionService;
  final ImagePickerService _imagePickerService;
  final AppDatabase _database = AppDatabase.instance;

  bool _initialized = false;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.system;
  String? _selectedImagePath;
  CaptionTone? _selectedTone;
  SocialPlatform? _selectedPlatform = SocialPlatform.instagram;
  AppLanguage _selectedLanguage = AppLanguage.english;
  CaptionResult? _currentResult;
  int _selectedSuggestionIndex = 0;
  CaptionRecord? _currentRecord;
  List<CaptionRecord> _history = const [];
  String? _errorMessage;

  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  String? get selectedImagePath => _selectedImagePath;
  CaptionTone? get selectedTone => _selectedTone;
  SocialPlatform? get selectedPlatform => _selectedPlatform;
  AppLanguage get selectedLanguage => _selectedLanguage;
  CaptionResult? get currentResult => _currentResult;
  int get selectedSuggestionIndex => _selectedSuggestionIndex;
  CaptionRecord? get currentRecord => _currentRecord;
  List<CaptionRecord> get history => _history;
  String? get errorMessage => _errorMessage;
  bool get hasConfiguredApiKey => _aiCaptionService.isConfigured;

  List<CaptionRecord> get favorites =>
      _history.where((record) => record.isFavorite).toList();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await loadHistory();
    _initialized = true;
    notifyListeners();
  }

  Future<bool> pickImage(ImageSource source) async {
    final file = await _imagePickerService.pickImage(source);
    if (file == null) {
      return false;
    }

    _selectedImagePath = file.path;
    _currentResult = null;
    _currentRecord = null;
    _selectedSuggestionIndex = 0;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void setTone(CaptionTone? tone) {
    _selectedTone = tone;
    notifyListeners();
  }

  void setPlatform(SocialPlatform? platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> generateCaption({bool save = true}) async {
    final imagePath = _selectedImagePath;
    if (imagePath == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _aiCaptionService.generateCaption(
        imagePath: imagePath,
        selectedTone: _selectedTone,
        platform: _selectedPlatform,
        language: _selectedLanguage,
      );

      _currentResult = result;
      _selectedSuggestionIndex = 0;

      final initialSuggestion = result.suggestions.first;
      final draft = CaptionRecord(
        imagePath: imagePath,
        caption: initialSuggestion.caption,
        hashtags: initialSuggestion.hashtags,
        timestamp: DateTime.now(),
        tone: _selectedTone ?? result.detectedTone,
        platform: _selectedPlatform,
        language: _selectedLanguage,
        analysisSummary: result.analysis.summary,
        isFavorite: _currentRecord?.isFavorite ?? false,
      );

      if (save) {
        final id = await _database.insertCaption(draft);
        _currentRecord = draft.copyWith(id: id);
        await loadHistory(notify: false);
      } else {
        _currentRecord = draft;
      }
    } on CaptionGenerationException catch (error) {
      _errorMessage = error.message;
      _currentResult = null;
      _currentRecord = null;
    } catch (_) {
      _errorMessage =
          'Something went wrong while generating the caption. Please try again.';
      _currentResult = null;
      _currentRecord = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> regenerateCaption() async {
    await generateCaption();
  }

  Future<void> selectSuggestion(int index) async {
    final result = _currentResult;
    final record = _currentRecord;
    if (result == null ||
        record == null ||
        index >= result.suggestions.length) {
      return;
    }

    _selectedSuggestionIndex = index;
    final suggestion = result.suggestions[index];
    final updated = record.copyWith(
      caption: suggestion.caption,
      hashtags: suggestion.hashtags,
      tone: _selectedTone ?? result.detectedTone,
      platform: _selectedPlatform,
      language: _selectedLanguage,
      analysisSummary: result.analysis.summary,
    );
    _currentRecord = updated;
    notifyListeners();

    if (updated.id != null) {
      await _database.updateCaption(updated);
      await loadHistory(notify: false);
      notifyListeners();
    }
  }

  Future<void> loadHistory({bool notify = true}) async {
    _history = await _database.fetchCaptions();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> updateCurrentCaption(String caption) async {
    final record = _currentRecord;
    if (record == null || record.caption == caption) {
      return;
    }

    final updated = record.copyWith(caption: caption);
    _currentRecord = updated;
    notifyListeners();

    if (updated.id != null) {
      await _database.updateCaption(updated);
      await loadHistory(notify: false);
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(CaptionRecord record) async {
    final updated = record.copyWith(isFavorite: !record.isFavorite);
    if (updated.id == null) {
      return;
    }

    if (_currentRecord?.id == updated.id) {
      _currentRecord = updated;
    }

    await _database.updateCaption(updated);
    await loadHistory(notify: false);
    notifyListeners();
  }

  Future<void> deleteCaption(CaptionRecord record) async {
    if (record.id == null) {
      return;
    }

    await _database.deleteCaption(record.id!);
    if (_currentRecord?.id == record.id) {
      _currentRecord = null;
      _currentResult = null;
    }
    await loadHistory(notify: false);
    notifyListeners();
  }

  void reuseCaption(CaptionRecord record) {
    _selectedImagePath = record.imagePath;
    _selectedTone = record.tone;
    _selectedPlatform = record.platform;
    _selectedLanguage = record.language;
    _currentRecord = record;
    _currentResult = CaptionResult(
      analysis: ImageAnalysis(
        objects: const ['saved image', 'caption', 'history'],
        mood: 'saved',
        context: 'history library',
        summary: record.analysisSummary.isEmpty
            ? 'Saved caption from your history library.'
            : record.analysisSummary,
      ),
      suggestions: [
        CaptionSuggestion(caption: record.caption, hashtags: record.hashtags),
      ],
      detectedTone: record.tone ?? CaptionTone.viral,
      platform: record.platform,
      language: record.language,
      groupedHashtags: {
        'Trending': record.hashtags.take(3).toList(),
        'Niche': record.hashtags.skip(3).toList(),
      },
    );
    _selectedSuggestionIndex = 0;
    _errorMessage = null;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    notifyListeners();
  }
}
