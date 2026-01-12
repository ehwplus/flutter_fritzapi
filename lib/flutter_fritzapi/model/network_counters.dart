/// Aggregated WAN counters as reported by the FRITZ!Box UI.
class OnlineCounters {
  const OnlineCounters({
    required this.totalBytes,
    required this.bytesSent,
    required this.bytesReceived,
    required this.raw,
  });

  /// Total bytes transferred (sent + received).
  final int totalBytes;

  /// Bytes sent from the FRITZ!Box to the internet.
  final int bytesSent;

  /// Bytes received by the FRITZ!Box from the internet.
  final int bytesReceived;

  /// Raw payload that was used to derive the counters.
  final Map<String, dynamic> raw;
}
