import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MM.yyyy').format(date);
  }
}
