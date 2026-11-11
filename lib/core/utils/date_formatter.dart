import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime? date, {String pattern = 'dd MMM yyyy'}) {
    if (date == null) return '-';
    return DateFormat(pattern).format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatFull(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}
