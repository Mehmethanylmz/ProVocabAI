import 'package:flutter/material.dart';

class LanguageManager {
  static final LanguageManager _instance = LanguageManager._init();
  static LanguageManager get instance => _instance;

  LanguageManager._init();

  final String assetPath = 'assets/lang';

  final List<Locale> supportedLocales = const [
    Locale('en', 'US'), // İngilizce
    Locale('tr', 'TR'), // Türkçe
    Locale('es', 'ES'), // İspanyolca
    Locale('de', 'DE'), // Almanca
    Locale('fr', 'FR'), // Fransızca
    Locale('pt', 'PT'), // Portekizce
  ];
}
