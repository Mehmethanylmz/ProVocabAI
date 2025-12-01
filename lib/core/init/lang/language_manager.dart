import 'package:flutter/material.dart';

class LanguageManager {
  static final LanguageManager _instance = LanguageManager._init();
  static LanguageManager get instance => _instance;

  LanguageManager._init();

  final String assetPath = 'assets/lang';

  final List<Locale> supportedLocales = const [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('pt', 'PT'),
  ];

  final Map<String, String> _shortToLongMap = {
    'tr': 'tr-TR',
    'en': 'en-US',
    'es': 'es-ES',
    'de': 'de-DE',
    'fr': 'fr-FR',
    'pt': 'pt-PT',
  };

  final Map<String, String> _nativeLanguageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
  };

  String getLocaleString(Locale locale) {
    return "${locale.languageCode}-${locale.countryCode}";
  }

  String getLanguageName(String code) {
    final shortCode = getShortCodeFromString(code);
    return _nativeLanguageNames[shortCode] ?? code;
  }

  String getShortCodeFromString(String longCode) {
    if (longCode.contains('-')) {
      return longCode.split('-')[0];
    } else if (longCode.contains('_')) {
      return longCode.split('_')[0];
    }
    return longCode;
  }

  String normalizeDeviceLocale(String deviceLocale) {
    String normalized = deviceLocale.replaceAll('_', '-');

    String shortCode = getShortCodeFromString(normalized);

    try {
      final supportedLocale = supportedLocales.firstWhere(
        (element) => element.languageCode == shortCode,
      );
      return getLocaleString(supportedLocale);
    } catch (e) {
      return 'en-US';
    }
  }

  String getTtsLocale(String shortCode) {
    return _shortToLongMap[shortCode] ??
        '${shortCode}-${shortCode.toUpperCase()}';
  }
}
