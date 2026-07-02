import 'caption_record.dart';

class ImageAnalysis {
  const ImageAnalysis({
    required this.objects,
    required this.mood,
    required this.context,
    required this.summary,
  });

  final List<String> objects;
  final String mood;
  final String context;
  final String summary;
}

class CaptionSuggestion {
  const CaptionSuggestion({required this.caption, required this.hashtags});

  final String caption;
  final List<String> hashtags;
}

class CaptionResult {
  const CaptionResult({
    required this.analysis,
    required this.suggestions,
    required this.detectedTone,
    required this.platform,
    required this.language,
    required this.groupedHashtags,
  });

  final ImageAnalysis analysis;
  final List<CaptionSuggestion> suggestions;
  final CaptionTone detectedTone;
  final SocialPlatform? platform;
  final AppLanguage language;
  final Map<String, List<String>> groupedHashtags;
}
