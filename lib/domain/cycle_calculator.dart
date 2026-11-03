/// Pure date-only cycle calculations. Dates are normalized to local calendar days.
class CycleEstimate {
  const CycleEstimate(
      {this.cycleDay,
      this.nextPeriod,
      this.cycleLength,
      this.intervalCount = 0,
      this.variable = false});
  final int? cycleDay;
  final DateTime? nextPeriod;
  final int? cycleLength;
  final int intervalCount;
  final bool variable;
}

class CycleCalculator {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static List<int> intervals(List<DateTime> starts) {
    final sorted = starts.map(day).toSet().toList()..sort();
    final out = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap >= 15 && gap <= 90) out.add(gap);
    }
    return out;
  }

  static int? median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final n = sorted.length;
    return n.isOdd
        ? sorted[n ~/ 2]
        : ((sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2).round();
  }

  static CycleEstimate estimate(
      {required List<DateTime> starts,
      required DateTime today,
      int? usualCycleLength,
      int minimumIntervals = 2}) {
    final sorted = starts.map(day).toSet().toList()..sort();
    if (sorted.isEmpty) return const CycleEstimate();
    final history = intervals(sorted);
    final enough = history.length >= minimumIntervals;
    final length = enough ? median(history) : usualCycleLength;
    final t = day(today), last = sorted.last;
    final variable = history.length >= 2 &&
        (history.reduce((a, b) => a > b ? a : b) -
                history.reduce((a, b) => a < b ? a : b) >=
            10);
    return CycleEstimate(
        cycleDay: t.isBefore(last) ? null : t.difference(last).inDays + 1,
        nextPeriod: length == null ? null : last.add(Duration(days: length)),
        cycleLength: length,
        intervalCount: history.length,
        variable: variable);
  }
}
