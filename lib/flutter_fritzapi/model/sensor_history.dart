import 'energy_stats.dart';

/// Time buckets supported by the FRITZ!Box stats API.
enum HistoryRange { day, week, month, twoYears }

String historyRangeLabel(HistoryRange range) {
  switch (range) {
    case HistoryRange.day:
      return '24h';
    case HistoryRange.week:
      return 'Woche';
    case HistoryRange.month:
      return 'Monat';
    case HistoryRange.twoYears:
      return '2 Jahre';
  }
}

/// Aggregated power stats across multiple time buckets.
class PowerHistory {
  const PowerHistory({
    this.day,
    this.week,
    this.month,
    this.twoYears,
    this.raw = const <HistoryRange, Map<String, dynamic>>{},
  });

  final EnergyStats? day;
  final EnergyStats? week;
  final EnergyStats? month;
  final EnergyStats? twoYears;
  final Map<HistoryRange, Map<String, dynamic>> raw;

  bool get isEmpty =>
      day == null && week == null && month == null && twoYears == null;
}

enum SensorStatType { temperature, humidity }

/// Time series stats for temperature or humidity.
class SensorHistory {
  const SensorHistory({
    required this.type,
    required this.range,
    required this.values,
    required this.raw,
    this.intervalSeconds,
    this.level,
  });

  final SensorStatType type;
  final HistoryRange range;
  final List<double> values;
  final int? intervalSeconds;
  final int? level;
  final Map<String, dynamic> raw;

  double? get average {
    if (values.isEmpty) {
      return null;
    }
    final double sum = values.reduce((double a, double b) => a + b);
    return sum / values.length;
  }

  double? get last => values.isEmpty ? null : values.last;
}
