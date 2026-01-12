/// Represents a Wi‑Fi client known to the FRITZ!Box.
class WifiClient {
  const WifiClient({required this.name, this.ip, this.mac, this.connectionType, this.isOnline = false, this.raw});

  /// Human readable device name or fallback.
  final String name;

  /// IPv4 or IPv6 address if available.
  final String? ip;

  /// MAC address reported by the FRITZ!Box.
  final String? mac;

  /// Connection type (e.g. WLAN/LAN) if exposed.
  final String? connectionType;

  /// Whether the device is currently online.
  final bool isOnline;

  /// Raw payload that originated this client entry.
  final Map<String, dynamic>? raw;

  /// Try to resolve device type
  WifiDeviceType? get deviceType => WifiDeviceType.fromDeviceName(name);
}

enum WifiDeviceType {
  security_camera,
  smartphone,
  tablet,
  computer,
  tp_tapo_plug,
  fritz_repeater,
  speaker,
  google_chromecast,
  television,
  gamingConsole,
  unknown;

  static WifiDeviceType? fromDeviceName(String? value) {
    if (value != null) {
      final deviceName = value.toLowerCase();
      if (deviceName.contains('indoorcam')) {
        return security_camera;
      } else if (deviceName.contains('speaker')) {
        return speaker;
      } else if (deviceName.contains('chromecast')) {
        return google_chromecast;
      } else if (deviceName.contains('webOS')) {
        return television;
      } else if (deviceName.contains('xbox')) {
        return gamingConsole;
      } else if (deviceName.contains('macbox') || deviceName.contains('pc') || deviceName.contains('laptop')) {
        return computer;
      } else if (deviceName.contains('fritz!repeater')) {
        return fritz_repeater;
      } else if (deviceName.contains('fritz!repeater')) {
        return tp_tapo_plug;
      } else if (!deviceName.contains('pad') &&
          (deviceName.contains('android') || deviceName.contains('honor-magic'))) {
        return smartphone;
      } else if (deviceName.contains('ipad') || deviceName.contains('mediapad')) {
        return tablet;
      }
    }
    return unknown;
  }
}
