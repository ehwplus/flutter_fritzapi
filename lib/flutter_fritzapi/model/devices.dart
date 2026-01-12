import 'device.dart';

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
