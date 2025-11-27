extension StringExtension on String? {
  // Null veya Boş kontrolü
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrNoEmpty => this != null && this!.isNotEmpty;
}

extension StringValidationExtension on String {
  // Email kontrolü
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    );
    return emailRegex.hasMatch(this);
  }

  // Şifre kontrolü (Min 6 karakter)
  bool get isValidPassword => length >= 6;

  // İlk harfi büyütme (capitalize)
  String get toCapitalized {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
