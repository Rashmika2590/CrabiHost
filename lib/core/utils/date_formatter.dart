import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dayMonthFormat = DateFormat('dd MMM');
  static final _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// Formats: 23 Sep 2026
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  /// Formats: 03:00 PM
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, hour, minute);
      return _timeFormat.format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  /// Formats: 23 Sep 2026, 03:00 PM
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTimeFormat.format(date);
  }

  /// Formats: 23 Sep
  static String formatDayMonth(DateTime? date) {
    if (date == null) return '—';
    return _dayMonthFormat.format(date);
  }

  /// Parses API date string (yyyy-MM-dd)
  static DateTime? parseApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return _apiDateFormat.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Returns relative label: Today, Tomorrow, Yesterday, or formatted date
  static String relativeDate(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return _dateFormat.format(date);
  }

  /// Duration between two dates in human-readable form
  static String duration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) return '—';
    final diff = checkOut.difference(checkIn).inDays;
    if (diff == 1) return '1 night';
    return '$diff nights';
  }
}
