/// Represents a Wi‑Fi client known to the FRITZ!Box.
class WifiClient {
  const WifiClient({
    required this.name,
    this.ip,
    this.mac,
    this.connectionType,
    this.isOnline = false,
    this.raw,
  });

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
}
