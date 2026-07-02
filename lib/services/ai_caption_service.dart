import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../models/caption_record.dart';
import '../models/caption_result.dart';

abstract class CaptionGenerationService {
  bool get isConfigured;

  Future<CaptionResult> generateCaption({
    required String imagePath,
    CaptionTone? selectedTone,
    SocialPlatform? platform,
    required AppLanguage language,
  });
}

const Map<String, Object?> _responseSchema = {
  'type': 'object',
  'properties': {
    'analysis': {
      'type': 'object',
      'properties': {
        'objects': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'mood': {'type': 'string'},
        'context': {'type': 'string'},
        'summary': {'type': 'string'},
      },
      'required': ['objects', 'mood', 'context', 'summary'],
      'additionalProperties': false,
    },
    'detected_tone': {
      'type': 'string',
      'enum': ['funny', 'professional', 'romantic', 'viral'],
    },
    'suggestions': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'caption': {'type': 'string'},
          'hashtags': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['caption', 'hashtags'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['analysis', 'detected_tone', 'suggestions'],
  'additionalProperties': false,
};

class OpenAiCaptionService implements CaptionGenerationService {
  OpenAiCaptionService({
    required String apiKey,
    http.Client? httpClient,
    this.model = 'gpt-4.1-mini',
  }) : _apiKey = apiKey.trim(),
       _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final http.Client _httpClient;
  final String model;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<CaptionResult> generateCaption({
    required String imagePath,
    CaptionTone? selectedTone,
    SocialPlatform? platform,
    required AppLanguage language,
  }) async {
    if (!isConfigured) {
      throw const CaptionGenerationException(
        'OpenAI API key missing. Run the app with --dart-define=OPENAI_API_KEY=your_key.',
      );
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw const CaptionGenerationException(
        'The selected image could not be found.',
      );
    }

    final mimeType = _mimeTypeFor(imagePath);
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final prompt = _buildPrompt(
      selectedTone: selectedTone,
      platform: platform,
      language: language,
    );

    final response = await _httpClient.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $_apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': [
          {
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': prompt},
              {
                'type': 'input_image',
                'image_url': 'data:$mimeType;base64,$base64Image',
              },
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'caption_response',
            'schema': _responseSchema,
            'strict': true,
          },
        },
        'max_output_tokens': 900,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final message =
          (body['error'] as Map<String, dynamic>?)?['message']?.toString() ??
          'OpenAI request failed with status ${response.statusCode}.';
      throw CaptionGenerationException(message);
    }

    final payload = _extractStructuredPayload(body);
    final analysisJson =
        payload['analysis'] as Map<String, dynamic>? ?? const {};
    final suggestionsJson =
        payload['suggestions'] as List<dynamic>? ?? const [];
    final detectedToneName =
        payload['detected_tone']?.toString().trim().toLowerCase() ?? '';

    final suggestions = suggestionsJson
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => CaptionSuggestion(
            caption: item['caption']?.toString().trim() ?? '',
            hashtags: (item['hashtags'] as List<dynamic>? ?? const [])
                .map((tag) => _normalizeHashtag(tag.toString()))
                .where((tag) => tag.isNotEmpty)
                .toList(),
          ),
        )
        .where((item) => item.caption.isNotEmpty && item.hashtags.isNotEmpty)
        .toList();

    if (suggestions.isEmpty) {
      throw const CaptionGenerationException(
        'OpenAI returned an empty caption result.',
      );
    }

    final detectedTone =
        _toneFromName(detectedToneName) ?? selectedTone ?? CaptionTone.viral;
    final primaryHashtags = suggestions.first.hashtags;

    return CaptionResult(
      analysis: ImageAnalysis(
        objects: (analysisJson['objects'] as List<dynamic>? ?? const [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        mood: analysisJson['mood']?.toString().trim() ?? 'balanced',
        context: analysisJson['context']?.toString().trim() ?? 'social post',
        summary:
            analysisJson['summary']?.toString().trim() ??
            'The image was analyzed successfully.',
      ),
      suggestions: suggestions,
      detectedTone: detectedTone,
      platform: platform,
      language: language,
      groupedHashtags: _buildHashtagGroups(primaryHashtags),
    );
  }

  String _buildPrompt({
    required CaptionTone? selectedTone,
    required SocialPlatform? platform,
    required AppLanguage language,
  }) {
    final languageInstruction = switch (language) {
      AppLanguage.english => 'Write everything in English.',
      AppLanguage.hindi =>
        'Write everything in Hindi using natural modern Hindi.',
    };
    final toneInstruction = selectedTone == null
        ? 'Infer the most suitable caption tone from the image.'
        : 'Use a ${selectedTone.promptStyle} tone.';
    final platformInstruction = platform == null
        ? 'Keep the result suitable for a general social media post.'
        : 'Optimize it for ${platform.label}, which is ${platform.audienceHint}.';

    return '''
Analyze the attached image and generate social media captions and hashtags.

$languageInstruction
$toneInstruction
$platformInstruction

Return valid JSON matching the provided schema.
Rules:
- Provide exactly 3 caption suggestions.
- Each caption should be concise, natural, and ready to post.
- Each suggestion must include 6 to 10 hashtags.
- Hashtags must begin with # and contain no spaces.
- Keep the analysis grounded in what is visible in the image.
- detected_tone must be one of: funny, professional, romantic, viral.
''';
  }

  Map<String, dynamic> _extractStructuredPayload(Map<String, dynamic> body) {
    final output = body['output'];
    if (output is! List<dynamic>) {
      throw const CaptionGenerationException(
        'OpenAI response did not include output items.',
      );
    }

    for (final item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final content = item['content'];
      if (content is! List<dynamic>) {
        continue;
      }
      for (final part in content) {
        if (part is! Map<String, dynamic>) {
          continue;
        }
        final refusal = part['refusal']?.toString();
        if (refusal != null && refusal.isNotEmpty) {
          throw CaptionGenerationException(refusal);
        }

        final textValue =
            part['text']?.toString() ??
            part['output_text']?.toString() ??
            part['value']?.toString();
        if (textValue != null && textValue.trim().isNotEmpty) {
          return jsonDecode(textValue) as Map<String, dynamic>;
        }
      }
    }

    throw const CaptionGenerationException(
      'OpenAI response could not be parsed into caption JSON.',
    );
  }

  CaptionTone? _toneFromName(String value) {
    for (final tone in CaptionTone.values) {
      if (tone.name == value) {
        return tone;
      }
    }
    return null;
  }

  Map<String, List<String>> _buildHashtagGroups(List<String> hashtags) {
    final normalized = hashtags
        .map(_normalizeHashtag)
        .where((tag) => tag.isNotEmpty)
        .toList();

    return {
      'Broad Reach': normalized.take(3).toList(),
      'Community': normalized.skip(3).take(3).toList(),
      'Extra': normalized.skip(6).toList(),
    }..removeWhere((_, value) => value.isEmpty);
  }

  String _normalizeHashtag(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) {
      return '';
    }
    return compact.startsWith('#') ? compact : '#$compact';
  }

  String _mimeTypeFor(String imagePath) {
    final extension = p.extension(imagePath).toLowerCase();
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}

class MockAiCaptionService implements CaptionGenerationService {
  @override
  bool get isConfigured => true;

  @override
  Future<CaptionResult> generateCaption({
    required String imagePath,
    CaptionTone? selectedTone,
    SocialPlatform? platform,
    required AppLanguage language,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final subject = _cleanupSubject(p.basenameWithoutExtension(imagePath));
    final keywords = _extractKeywords(subject);
    final analysis = _analyzeImage(subject, keywords, language);
    final detectedTone = _detectTone(subject, keywords, analysis);
    final effectiveTone = selectedTone ?? detectedTone;
    final seed = DateTime.now().microsecondsSinceEpoch ^ imagePath.hashCode;

    final suggestions = List.generate(
      3,
      (index) => _buildSuggestion(
        subject: subject,
        keywords: keywords,
        analysis: analysis,
        tone: effectiveTone,
        platform: platform,
        language: language,
        seed: seed + (index * 37),
      ),
    );

    final groupedHashtags = _buildGroupedHashtags(
      subject: subject,
      keywords: keywords,
      tone: effectiveTone,
      platform: platform,
      language: language,
      seed: seed,
    );

    return CaptionResult(
      analysis: analysis,
      suggestions: suggestions,
      detectedTone: detectedTone,
      platform: platform,
      language: language,
      groupedHashtags: groupedHashtags,
    );
  }

  String _cleanupSubject(String raw) {
    final sanitized = raw
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return sanitized.isEmpty ? 'captured moment' : sanitized;
  }

  List<String> _extractKeywords(String subject) {
    const stopWords = {
      'img',
      'image',
      'photo',
      'pic',
      'snapshot',
      'the',
      'a',
      'an',
      'and',
      'with',
      'for',
      'from',
      'this',
      'that',
      'my',
      'our',
      'your',
      'new',
    };

    return subject
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toList();
  }

  ImageAnalysis _analyzeImage(
    String subject,
    List<String> keywords,
    AppLanguage language,
  ) {
    final objects = _detectObjects(subject, keywords);
    final mood = _detectMood(subject, keywords);
    final context = _detectContext(subject, keywords);

    final summary = language == AppLanguage.hindi
        ? 'इस इमेज में ${objects.join(', ')} दिख रहे हैं, मूड $mood है और सीन $context जैसा लग रहा है।'
        : 'This image appears to feature ${objects.join(', ')}, with a $mood mood in a $context setting.';

    return ImageAnalysis(
      objects: objects,
      mood: mood,
      context: context,
      summary: summary,
    );
  }

  List<String> _detectObjects(String subject, List<String> keywords) {
    final value = '$subject ${keywords.join(' ')}'.toLowerCase();

    if (RegExp(r'(dog|puppy|cat|kitten|pet)').hasMatch(value)) {
      return ['pet', 'portrait', 'personality'];
    }
    if (RegExp(r'(coffee|food|brunch|dinner|cake|dessert)').hasMatch(value)) {
      return ['food', 'texture', 'table setup'];
    }
    if (RegExp(
      r'(office|desk|laptop|meeting|workspace|team)',
    ).hasMatch(value)) {
      return ['workspace', 'details', 'professional setup'];
    }
    if (RegExp(r'(beach|mountain|travel|sunset|nature|trip)').hasMatch(value)) {
      return ['landscape', 'light', 'travel scene'];
    }
    if (RegExp(r'(couple|wedding|love|date|anniversary)').hasMatch(value)) {
      return ['people', 'emotion', 'connection'];
    }
    if (RegExp(r'(party|friends|concert|celebration)').hasMatch(value)) {
      return ['people', 'motion', 'event energy'];
    }

    return ['subject', 'lighting', 'visual detail'];
  }

  String _detectMood(String subject, List<String> keywords) {
    final value = '$subject ${keywords.join(' ')}'.toLowerCase();

    if (RegExp(r'(love|wedding|date|anniversary|sunset)').hasMatch(value)) {
      return 'romantic';
    }
    if (RegExp(r'(office|meeting|workspace|launch|brand)').hasMatch(value)) {
      return 'focused';
    }
    if (RegExp(
      r'(party|friends|pet|dog|cat|selfie|vacation)',
    ).hasMatch(value)) {
      return 'playful';
    }

    return 'bold';
  }

  String _detectContext(String subject, List<String> keywords) {
    final value = '$subject ${keywords.join(' ')}'.toLowerCase();

    if (RegExp(
      r'(beach|mountain|travel|sunset|nature|trip|ocean)',
    ).hasMatch(value)) {
      return 'outdoor lifestyle';
    }
    if (RegExp(
      r'(office|meeting|workspace|team|desk|laptop)',
    ).hasMatch(value)) {
      return 'professional environment';
    }
    if (RegExp(r'(food|coffee|brunch|dinner|cake|dessert)').hasMatch(value)) {
      return 'editorial food moment';
    }
    if (RegExp(r'(party|friends|concert|celebration)').hasMatch(value)) {
      return 'social scene';
    }
    if (RegExp(r'(couple|wedding|love|date|anniversary)').hasMatch(value)) {
      return 'intimate setting';
    }

    return 'lifestyle frame';
  }

  CaptionTone _detectTone(
    String subject,
    List<String> keywords,
    ImageAnalysis analysis,
  ) {
    final value =
        '$subject ${keywords.join(' ')} ${analysis.mood} ${analysis.context}'
            .toLowerCase();

    if (RegExp(
      r'(romantic|love|wedding|anniversary|intimate)',
    ).hasMatch(value)) {
      return CaptionTone.romantic;
    }
    if (RegExp(
      r'(focused|professional|workspace|brand|meeting)',
    ).hasMatch(value)) {
      return CaptionTone.professional;
    }
    if (RegExp(r'(playful|pet|party|friends|vacation)').hasMatch(value)) {
      return CaptionTone.funny;
    }

    return CaptionTone.viral;
  }

  CaptionSuggestion _buildSuggestion({
    required String subject,
    required List<String> keywords,
    required ImageAnalysis analysis,
    required CaptionTone tone,
    required SocialPlatform? platform,
    required AppLanguage language,
    required int seed,
  }) {
    final hook = _pick(_hooks(tone, platform, language), seed);
    final perspective = _pick(_perspectives(analysis, language), seed + 5);
    final payoff = _pick(_payoffs(tone, platform, language), seed + 9);
    final detail = keywords.isEmpty
        ? _pick(_detailFallbacks(language), seed + 13)
        : _buildDetailAccent(keywords, language, seed + 17);

    final caption = '$hook $perspective $detail $payoff';
    final hashtags = _buildSuggestionTags(
      subject: subject,
      keywords: keywords,
      tone: tone,
      platform: platform,
      language: language,
      seed: seed,
    );

    return CaptionSuggestion(caption: caption.trim(), hashtags: hashtags);
  }

  List<String> _hooks(
    CaptionTone tone,
    SocialPlatform? platform,
    AppLanguage language,
  ) {
    if (language == AppLanguage.hindi) {
      return switch (tone) {
        CaptionTone.funny => [
          'यह फोटो खुद ही कैप्शन मांग रही थी।',
          'इस फ्रेम में अलग ही fun energy है।',
          'थोड़ा chaos, थोड़ा charm, और पूरा vibe.',
        ],
        CaptionTone.professional => [
          'इस विजुअल में clarity और intent दोनों दिखते हैं।',
          'यह फ्रेम quietly strong impression बनाता है।',
          'साफ presentation, strong presence.',
        ],
        CaptionTone.romantic => [
          'इस फ्रेम में softness अपने आप महसूस होती है।',
          'कुछ moments को बस संभाल कर रखना होता है।',
          'यह तस्वीर दिल के पास रुक जाती है।',
        ],
        CaptionTone.viral => [
          'यह वही फोटो है जो scroll रोक देती है।',
          'इस फ्रेम में instant attention वाली energy है।',
          'यह पोस्ट timeline पर टिकने वाली है।',
        ],
      };
    }

    return switch (tone) {
      CaptionTone.funny => [
        'This frame had enough personality to post itself.',
        'A little chaos, a lot of charm.',
        'Some photos just arrive with better timing than the rest.',
      ],
      CaptionTone.professional => [
        'A strong visual usually says more with less.',
        'This frame lands with clarity and intention.',
        'Quietly polished, but hard to ignore.',
      ],
      CaptionTone.romantic => [
        'Some images hold onto a feeling longer than words do.',
        'A softer frame with a lasting impression.',
        'This one carries warmth without trying too hard.',
      ],
      CaptionTone.viral => [
        'This is the kind of image that stops the scroll.',
        'Built with just enough presence to be remembered.',
        'The camera roll had a standout, and this is it.',
      ],
    };
  }

  List<String> _perspectives(ImageAnalysis analysis, AppLanguage language) {
    if (language == AppLanguage.hindi) {
      return [
        'इसमें ${analysis.objects.first} और ${analysis.context} की feel साफ दिख रही है।',
        'मूड ${analysis.mood} है और पूरा scene naturally balanced लग रहा है।',
        'light, detail और ${analysis.context} साथ में strong story बना रहे हैं।',
      ];
    }

    return [
      'It captures ${analysis.objects.first} in a ${analysis.context} setting with a ${analysis.mood} mood.',
      'The mix of ${analysis.objects.first}, detail, and atmosphere makes the whole scene feel intentional.',
      'There is a clear ${analysis.mood} energy here, shaped by the ${analysis.context} around it.',
    ];
  }

  String _buildDetailAccent(
    List<String> keywords,
    AppLanguage language,
    int seed,
  ) {
    final word = _prettify(_pick(keywords, seed));
    return language == AppLanguage.hindi
        ? '$word detail बार-बार attention खींच रही है।'
        : 'The $word detail keeps pulling the eye back in.';
  }

  List<String> _detailFallbacks(AppLanguage language) {
    return language == AppLanguage.hindi
        ? [
            'छोटे details इस फोटो को और memorable बना रहे हैं।',
            'पूरे फ्रेम में balance और mood अच्छी तरह बना हुआ है।',
            'इस विजुअल में presence बहुत natural लग रही है।',
          ]
        : [
            'The little details do more work than they first reveal.',
            'There is a nice balance between mood and clarity here.',
            'The visual carries a natural sense of presence throughout.',
          ];
  }

  List<String> _payoffs(
    CaptionTone tone,
    SocialPlatform? platform,
    AppLanguage language,
  ) {
    if (language == AppLanguage.hindi) {
      return switch (platform) {
        SocialPlatform.instagram => [
          'यह feed, save और share तीनों के लिए ready है.',
          'Grid पर यह फोटो आसानी से standout करेगी.',
          'यह Instagram पर clean और catchy लगेगी.',
        ],
        SocialPlatform.linkedin => [
          'यह LinkedIn पर thoughtful और polished लगेगी.',
          'Professional audience के लिए यह visual strong signal देता है.',
          'यह post insight और presentation दोनों carry करती है.',
        ],
        SocialPlatform.twitter => [
          'Timeline पर यह short caption के साथ भी impact डालेगी.',
          'Twitter के लिए इसमें quick attention वाली quality है.',
          'यह fast scroll में भी याद रह जाएगी.',
        ],
        null => [
          'यह post किसी भी platform पर comfortably fit हो सकती है.',
          'यह visual अलग-अलग audiences के लिए काम कर सकती है.',
          'यह moment share करने लायक feel देती है.',
        ],
      };
    }

    return switch (platform) {
      SocialPlatform.instagram => [
        'Made for the feed, the save, and the second look.',
        'It fits Instagram without feeling overworked.',
        'This one earns its place on the grid.',
      ],
      SocialPlatform.linkedin => [
        'It reads polished enough for a more thoughtful audience.',
        'This carries well in a professional context too.',
        'A strong fit for a cleaner, insight-led post.',
      ],
      SocialPlatform.twitter => [
        'It has exactly the right energy for a quick, sharp post.',
        'Short post, strong signal.',
        'This would travel well on a fast-moving timeline.',
      ],
      null => [
        'It works as a versatile post without forcing the tone.',
        'Easy to share anywhere without losing the mood.',
        'The visual holds up across formats and audiences.',
      ],
    };
  }

  Map<String, List<String>> _buildGroupedHashtags({
    required String subject,
    required List<String> keywords,
    required CaptionTone tone,
    required SocialPlatform? platform,
    required AppLanguage language,
    required int seed,
  }) {
    final trending = <String>{
      switch (tone) {
        CaptionTone.funny => '#MoodDrop',
        CaptionTone.professional => '#ContentStrategy',
        CaptionTone.romantic => '#MomentCaptured',
        CaptionTone.viral => '#ScrollStopper',
      },
      switch (platform) {
        SocialPlatform.instagram => '#InstaReady',
        SocialPlatform.linkedin => '#LinkedInPost',
        SocialPlatform.twitter => '#TwitterPost',
        null => '#PostReady',
      },
      language == AppLanguage.hindi ? '#HindiContent' : '#EnglishCaption',
    };

    final niche = <String>{
      _toHashtag(subject),
      ...keywords.take(3).map(_toHashtag),
      if (tone == CaptionTone.professional) '#VisualBranding',
      if (tone == CaptionTone.romantic) '#SoftStorytelling',
      if (tone == CaptionTone.funny) '#PlayfulFrame',
      if (tone == CaptionTone.viral) '#ShareWorthy',
    };

    return {
      'Trending': trending.toList()..shuffle(Random(seed.abs())),
      'Niche': niche.toList()..shuffle(Random((seed + 19).abs())),
    };
  }

  List<String> _buildSuggestionTags({
    required String subject,
    required List<String> keywords,
    required CaptionTone tone,
    required SocialPlatform? platform,
    required AppLanguage language,
    required int seed,
  }) {
    final grouped = _buildGroupedHashtags(
      subject: subject,
      keywords: keywords,
      tone: tone,
      platform: platform,
      language: language,
      seed: seed,
    );

    return [...grouped['Trending']!.take(3), ...grouped['Niche']!.take(4)];
  }

  String _toHashtag(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_prettify)
        .toList();

    return words.isEmpty ? '#Moment' : '#${words.join()}';
  }

  String _prettify(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  T _pick<T>(List<T> items, int seed) {
    return items[seed.abs() % items.length];
  }
}

class CaptionGenerationException implements Exception {
  const CaptionGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
