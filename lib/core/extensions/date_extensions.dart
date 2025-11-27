import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  String get toFormattedDate {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String get toFormattedTime {
    return DateFormat('HH:mm').format(this);
  }
}
