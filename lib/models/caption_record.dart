import 'dart:convert';

import 'package:flutter/material.dart';

enum CaptionTone { funny, professional, romantic, viral }

enum SocialPlatform { instagram, linkedin, twitter }

enum AppLanguage { english, hindi }

extension CaptionToneX on CaptionTone {
  String get label => switch (this) {
    CaptionTone.funny => 'Funny',
    CaptionTone.professional => 'Professional',
    CaptionTone.romantic => 'Romantic',
    CaptionTone.viral => 'Viral',
  };

  String get promptStyle => switch (this) {
    CaptionTone.funny => 'witty and clever',
    CaptionTone.professional => 'polished and insight-driven',
    CaptionTone.romantic => 'warm and heartfelt',
    CaptionTone.viral => 'punchy and trend-aware',
  };

  IconData get icon => switch (this) {
    CaptionTone.funny => Icons.sentiment_very_satisfied_rounded,
    CaptionTone.professional => Icons.business_center_rounded,
    CaptionTone.romantic => Icons.favorite_rounded,
    CaptionTone.viral => Icons.local_fire_department_rounded,
  };
}

extension SocialPlatformX on SocialPlatform {
  String get label => switch (this) {
    SocialPlatform.instagram => 'Instagram',
    SocialPlatform.linkedin => 'LinkedIn',
    SocialPlatform.twitter => 'Twitter',
  };

  String get audienceHint => switch (this) {
    SocialPlatform.instagram => 'visual, expressive, and community-driven',
    SocialPlatform.linkedin => 'polished, thoughtful, and professional',
    SocialPlatform.twitter => 'fast, punchy, and conversation-first',
  };

  IconData get icon => switch (this) {
    SocialPlatform.instagram => Icons.photo_camera_back_rounded,
    SocialPlatform.linkedin => Icons.work_outline_rounded,
    SocialPlatform.twitter => Icons.alternate_email_rounded,
  };
}

extension AppLanguageX on AppLanguage {
  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.hindi => 'Hindi',
  };

  String get nativeLabel => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.hindi => 'Hindi',
  };

  IconData get icon => switch (this) {
    AppLanguage.english => Icons.translate_rounded,
    AppLanguage.hindi => Icons.g_translate_rounded,
  };
}

class CaptionRecord {
  const CaptionRecord({
    this.id,
    required this.imagePath,
    required this.caption,
    required this.hashtags,
    required this.timestamp,
    this.tone,
    this.platform,
    this.language = AppLanguage.english,
    this.analysisSummary = '',
    this.isFavorite = false,
  });

  final int? id;
  final String imagePath;
  final String caption;
  final List<String> hashtags;
  final DateTime timestamp;
  final CaptionTone? tone;
  final SocialPlatform? platform;
  final AppLanguage language;
  final String analysisSummary;
  final bool isFavorite;

  CaptionRecord copyWith({
    int? id,
    String? imagePath,
    String? caption,
    List<String>? hashtags,
    DateTime? timestamp,
    Object? tone = _sentinel,
    Object? platform = _sentinel,
    AppLanguage? language,
    String? analysisSummary,
    bool? isFavorite,
  }) {
    return CaptionRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      timestamp: timestamp ?? this.timestamp,
      tone: identical(tone, _sentinel) ? this.tone : tone as CaptionTone?,
      platform: identical(platform, _sentinel)
          ? this.platform
          : platform as SocialPlatform?,
      language: language ?? this.language,
      analysisSummary: analysisSummary ?? this.analysisSummary,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'caption': caption,
      'hashtags': jsonEncode(hashtags),
      'tone': tone?.name,
      'platform': platform?.name,
      'language': language.name,
      'analysis_summary': analysisSummary,
      'timestamp': timestamp.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory CaptionRecord.fromMap(Map<String, Object?> map) {
    return CaptionRecord(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      caption: map['caption'] as String,
      hashtags:
          (jsonDecode((map['hashtags'] as String?) ?? '[]') as List<dynamic>)
              .map((item) => item.toString())
              .toList(),
      tone: (map['tone'] as String?) == null
          ? null
          : CaptionTone.values.byName(map['tone'] as String),
      platform: (map['platform'] as String?) == null
          ? null
          : SocialPlatform.values.byName(map['platform'] as String),
      language: (map['language'] as String?) == null
          ? AppLanguage.english
          : AppLanguage.values.byName(map['language'] as String),
      analysisSummary: (map['analysis_summary'] as String?) ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }
}

const Object _sentinel = Object();
