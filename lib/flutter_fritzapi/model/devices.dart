import 'package:json_annotation/json_annotation.dart';

class Devices {
  const Devices({required this.devices});

  final List<Device> devices;

  Iterable<Device> getConnectedDevices({
    Iterable<DeviceCategory> acceptedDeviceCategories = const [DeviceCategory.SOCKET],
  }) => devices.where((device) {
    return device.isConnected && acceptedDeviceCategories.contains(device.category);
  });

  // ignore: sort_constructors_first
  factory Devices.fromJson(Map<String, dynamic> json) {
    final devicesJson = json['data']['devices'];
    final List<Device> devices = [];
    for (final deviceJson in devicesJson) {
      devices.add(Device.fromJson(deviceJson));
    }
    return Devices(devices: devices);
  }
}

class Device {
  const Device({
    required this.id,
    required this.displayName,
    required this.category,
    required this.model,
    required this.isConnected,
  });

  /// example: 16
  final int id;

  /// example: "Wohnzimmerheizung"
  final String displayName;
  final DeviceCategory category; // "THERMOSTAT"
  final bool isConnected;

  /// examples: "FRITZ!DECT 302", "FRITZ!DECT 200", "FRITZ!DECT 210"
  final String model;

  // ignore: sort_constructors_first
  factory Device.fromJson(Map<String, dynamic> json) {
    final bool isConnected = json['masterConnectionState'] == 'CONNECTED';
    return Device(
      id: json['id'],
      displayName: json['displayName'],
      model: json['model'],
      category: $enumDecode(_$DeviceCategoryEnumMap, json['category']),
      isConnected: isConnected,
    );
  }
}

enum DeviceCategory { THERMOSTAT, SOCKET, CONTROL, LAMP }

const _$DeviceCategoryEnumMap = {
  DeviceCategory.THERMOSTAT: 'THERMOSTAT',
  DeviceCategory.SOCKET: 'SOCKET',
  DeviceCategory.CONTROL: 'CONTROL',
  DeviceCategory.LAMP: 'LAMP',
};
