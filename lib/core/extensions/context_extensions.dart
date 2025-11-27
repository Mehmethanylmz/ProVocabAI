import 'package:flutter/material.dart';
import '../init/theme/app_theme_extension.dart';

/// Bu dosya SADECE Tema ve Renk erişimi içindir.
/// Boyutlandırma ve Padding işlemleri için [responsive_extension.dart] kullanılmalıdır.

extension ThemeExtension on BuildContext {
  // Theme verisine hızlı erişim
  ThemeData get theme => Theme.of(this);

  // Yazı stillerine hızlı erişim (context.textTheme.titleLarge)
  TextTheme get textTheme => theme.textTheme;

  // Standart renklere hızlı erişim (context.colors.primary)
  ColorScheme get colors => theme.colorScheme;

  // Bizim yazdığımız özel renklere hızlı erişim (context.ext.success)
  AppThemeExtension get ext => theme.extension<AppThemeExtension>()!;
}

extension FocusExtension on BuildContext {
  // Klavyeyi kapatmak için pratik yöntem
  void closeKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
