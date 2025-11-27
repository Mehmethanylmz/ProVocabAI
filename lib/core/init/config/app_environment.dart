import 'package:flutter/foundation.dart';

class AppEnvironment {
  // Proje moduna göre URL veya API Key değişimi için
  static bool get isProduction => kReleaseMode;
}
