import 'package:flutter_test/flutter_test.dart';
import 'package:upheal/utils/format_duration.dart';

void main() {
  group('formatDuration', () {
    test('returns "0m" for zero seconds', () {
      expect(formatDuration(0), '0m');
    });

    test('returns "0m" for negative seconds', () {
      expect(formatDuration(-1), '0m');
    });

    test('returns minutes only when under an hour', () {
      expect(formatDuration(30), '0m');
      expect(formatDuration(60), '1m');
      expect(formatDuration(600), '10m');
      expect(formatDuration(3540), '59m');
    });

    test('returns hours and minutes for exact hour', () {
      expect(formatDuration(3600), '1h');
      expect(formatDuration(7200), '2h');
    });

    test('returns hours and minutes for mixed durations', () {
      expect(formatDuration(3660), '1h 1m');
      expect(formatDuration(7260), '2h 1m');
      expect(formatDuration(35940), '9h 59m');
    });

    test('handles large durations', () {
      expect(formatDuration(36000), '10h');
      expect(formatDuration(35820), '9h 57m');
    });

    test('rounds down minutes (truncates seconds)', () {
      expect(formatDuration(65), '1m');
      expect(formatDuration(119), '1m');
    });
  });
}
