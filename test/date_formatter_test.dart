import 'package:flutter_test/flutter_test.dart';
import 'package:crabihost/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatDate correctly formats date', () {
      final date = DateTime(2026, 9, 23);
      expect(DateFormatter.formatDate(date), '23 Sep 2026');
      expect(DateFormatter.formatDate(null), '—');
    });

    test('formatTime correctly formats 24h to 12h', () {
      expect(DateFormatter.formatTime('14:30:00'), '02:30 PM');
      expect(DateFormatter.formatTime('09:15:00'), '09:15 AM');
      expect(DateFormatter.formatTime(null), '—');
      expect(DateFormatter.formatTime(''), '—');
    });

    test('parseApiDate handles valid and invalid strings', () {
      final parsed = DateFormatter.parseApiDate('2026-09-23');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 9);
      expect(parsed.day, 23);

      expect(DateFormatter.parseApiDate(null), isNull);
      expect(DateFormatter.parseApiDate('invalid'), isNull);
    });

    test('duration computes night count', () {
      final ci = DateTime(2026, 9, 20);
      final co = DateTime(2026, 9, 23);
      expect(DateFormatter.duration(ci, co), '3 nights');

      final coSingle = DateTime(2026, 9, 21);
      expect(DateFormatter.duration(ci, coSingle), '1 night');

      expect(DateFormatter.duration(null, co), '—');
    });
  });
}
