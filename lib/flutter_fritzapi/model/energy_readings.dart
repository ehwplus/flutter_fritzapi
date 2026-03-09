class EnergyReadings {
  const EnergyReadings({required this.entries});

  final List<EnergyReading> entries;

  bool get isEmpty => entries.isEmpty;
}

/// Snapshot of energy consumption for a given time interval.
class EnergyReading {
  const EnergyReading({required this.dateTime, this.energyWh, this.raw});

  final String? dateTime;

  /// Energy consumption in watt hours.
  final double? energyWh;

  final Object? raw;
}
