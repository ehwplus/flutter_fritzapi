import 'energy_stats.dart';

/// Time buckets supported by the FRITZ!Box stats API.
enum SensorHistoryInterval { day, week, month, twoYears }

enum SensorStatType { temperature, humidity }

String historyRangeLabel(SensorHistoryInterval range) {
  switch (range) {
    case SensorHistoryInterval.day:
      return '24h';
    case SensorHistoryInterval.week:
      return 'Woche';
    case SensorHistoryInterval.month:
      return 'Monat';
    case SensorHistoryInterval.twoYears:
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
    this.raw = const <SensorHistoryInterval, Map<String, dynamic>>{},
  });

  final EnergyStats? day;
  final EnergyStats? week;
  final EnergyStats? month;
  final EnergyStats? twoYears;
  final Map<SensorHistoryInterval, Map<String, dynamic>> raw;

  bool get isEmpty => day == null && week == null && month == null && twoYears == null;
}

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
  final SensorHistoryInterval range;
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
