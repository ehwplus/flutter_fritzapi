import 'package:json_annotation/json_annotation.dart';

class Device {
  const Device({
    required this.id,
    required this.displayName,
    required this.category,
    required this.model,
    required this.isConnected,
    this.temperatureCelsius,
    this.humidityPercent,
    this.powerWatt,
    this.capabilities = const <DeviceCapability>{},
    this.raw,
  });

  /// example: 16
  final int id;

  /// example: "Wohnzimmerheizung"
  final String displayName;
  final DeviceCategory category; // "THERMOSTAT"
  final bool isConnected;

  /// examples: "FRITZ!DECT 302", "FRITZ!DECT 200", "FRITZ!DECT 210"
  final String model;

  /// Current ambient temperature in °C if exposed by the device.
  final double? temperatureCelsius;

  /// Current relative humidity in % if exposed by the device.
  final double? humidityPercent;

  /// Current power draw in watts if exposed by the device.
  final double? powerWatt;

  /// Capabilities derived from the smart home device.
  final Set<DeviceCapability> capabilities;

  /// Full json payload for the device for consumers that need raw access.
  final Map<String, dynamic>? raw;

  // ignore: sort_constructors_first
  factory Device.fromJson(Map<String, dynamic> json) {
    final dynamic connectionState = json['masterConnectionState'];
    final bool isConnected = connectionState == 'CONNECTED' || connectionState == true;
    final dynamic rawId = json['id'];
    final int id = rawId is int
        ? rawId
        : rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final dynamic nestedDevice = json['device'];
    final String model = (json['model'] ?? (nestedDevice is Map<String, dynamic> ? nestedDevice['model'] : null) ?? '')
        .toString();
    final String displayName = (json['displayName'] ?? json['name'] ?? model).toString();
    final Iterable<Map<String, dynamic>> units =
        (json['units'] as List?)?.whereType<Map<String, dynamic>>() ?? const Iterable<Map<String, dynamic>>.empty();
    final List<Map<String, dynamic>> skills = units
        .expand(
          (unit) =>
              (unit['skills'] as List?)?.whereType<Map<String, dynamic>>() ??
              const Iterable<Map<String, dynamic>>.empty(),
        )
        .toList();
    final double? temperature = _extractNumber(skills, <String>['currentInCelsius', 'temperature', 'celsius']);
    final double? humidity = _extractNumber(skills, <String>[
      'humidity',
      'currentRelativeHumidity',
      'currentInPercent',
      'relativeHumidity',
    ]);
    final double? power = _extractNumber(skills, <String>['powerConsumptionInWatt', 'power', 'power_per_hour']);

    final Set<DeviceCapability> capabilities = <DeviceCapability>{};
    if (power != null) {
      capabilities.add(DeviceCapability.energy);
    }
    if (temperature != null) {
      capabilities.add(DeviceCapability.temperature);
    }
    if (humidity != null) {
      capabilities.add(DeviceCapability.humidity);
    }

    return Device(
      id: id,
      displayName: displayName,
      model: model,
      category: $enumDecode(_$DeviceCategoryEnumMap, json['category'], unknownValue: DeviceCategory.unknown),
      isConnected: isConnected,
      temperatureCelsius: temperature,
      humidityPercent: humidity,
      powerWatt: power,
      capabilities: capabilities,
      raw: json,
    );
  }
}

enum DeviceCategory { THERMOSTAT, SOCKET, CONTROL, LAMP, unknown }

enum DeviceCapability { energy, temperature, humidity }

const _$DeviceCategoryEnumMap = {
  DeviceCategory.THERMOSTAT: 'THERMOSTAT',
  DeviceCategory.SOCKET: 'SOCKET',
  DeviceCategory.CONTROL: 'CONTROL',
  DeviceCategory.LAMP: 'LAMP',
  DeviceCategory.unknown: 'UNKNOWN',
};

double? _extractNumber(List<Map<String, dynamic>> maps, List<String> keys) {
  for (final Map<String, dynamic> map in maps) {
    for (final String key in keys) {
      if (!map.containsKey(key)) {
        continue;
      }
      final double? parsed = _parseNumericValue(map[key]);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

double? _parseNumericValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final double? parsed = double.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  if (value is Map) {
    for (final dynamic nested in value.values) {
      final double? parsed = _parseNumericValue(nested);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  if (value is Iterable) {
    for (final dynamic nested in value) {
      final double? parsed = _parseNumericValue(nested);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}
