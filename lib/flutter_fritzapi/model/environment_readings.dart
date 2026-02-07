class EnvironmentReadings {
  const EnvironmentReadings({required this.entries});

  final List<EnvironmentReading> entries;

  bool get isEmpty => entries.isEmpty;

  Map<String, dynamic> toJson() {
    return {'entries': entries.map((EnvironmentReading e) => e.toJson()).toList()};
  }
}

/// Snapshot of the current environment
class EnvironmentReading {
  const EnvironmentReading({required this.dateTime, this.temperatureCelsius, this.humidityPercent, this.raw});

  final String? dateTime;

  /// The current temperature
  final double? temperatureCelsius;

  /// The current humidity in percent
  final double? humidityPercent;

  final Object? raw;

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime,
      'temperatureCelsius': temperatureCelsius,
      'humidityPercent': humidityPercent,
      'raw': raw,
    };
  }
}
