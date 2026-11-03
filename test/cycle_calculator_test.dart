import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/domain/cycle_calculator.dart';

void main() {
  group('CycleCalculator', () {
    test('empty history has no cycle day or prediction', () {
      final e =
          CycleCalculator.estimate(starts: [], today: DateTime(2026, 4, 2));
      expect(e.cycleDay, isNull);
      expect(e.nextPeriod, isNull);
    });
    test('single period start uses no medical guess without usual length', () {
      final e = CycleCalculator.estimate(
          starts: [DateTime(2026, 1, 31)], today: DateTime(2026, 2, 1));
      expect(e.cycleDay, 2);
      expect(e.nextPeriod, isNull);
    });
    test('median interval estimates across month and leap boundaries', () {
      final starts = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 29),
        DateTime(2024, 2, 26)
      ];
      final e = CycleCalculator.estimate(
          starts: starts, today: DateTime(2024, 2, 26));
      expect(e.cycleLength, 28);
      expect(e.nextPeriod, DateTime(2024, 3, 25));
    });
    test(
        'duplicate date does not create zero interval and usual length is labeled by count',
        () {
      final e = CycleCalculator.estimate(
          starts: [DateTime(2026, 4, 1), DateTime(2026, 4, 1)],
          today: DateTime(2026, 4, 1),
          usualCycleLength: 30);
      expect(e.intervalCount, 0);
      expect(e.nextPeriod, DateTime(2026, 5, 1));
    });
    test('impossible short intervals are excluded from interval history', () {
      expect(
          CycleCalculator.intervals(
              [DateTime(2026, 1, 1), DateTime(2026, 1, 5)]),
          isEmpty);
    });
  });
}
