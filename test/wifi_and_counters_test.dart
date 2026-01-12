import 'package:flutter_fritzapi/flutter_fritzapi.dart';
import 'package:test/test.dart';

void main() {
  group('Wi-Fi clients', () {
    test('parses active and passive client lists', () {
      final Map<String, dynamic> data = <String, dynamic>{
        'active': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Laptop',
            'ip': '192.168.178.10',
            'mac': 'aa:bb:cc:dd:ee:ff',
            'type': 'wifi',
            'active': true,
          },
        ],
        'passive': <Map<String, dynamic>>[
          <String, dynamic>{
            'details': <String, dynamic>{'name': 'Printer'},
            'ipv4': '192.168.178.20',
            'wlanMAC': '11:22:33:44:55:66',
            'isActive': false,
          },
        ],
      };

      final List<WifiClient> clients = parseWifiClients(data);

      expect(clients, hasLength(2));
      expect(clients.first.name, 'Laptop');
      expect(clients.first.isOnline, isTrue);
      expect(clients.last.name, 'Printer');
      expect(clients.last.isOnline, isFalse);
    });
  });

  group('Network counters', () {
    test('extracts counters from nested payload', () {
      final Map<String, dynamic> payload = <String, dynamic>{
        'overview': <String, dynamic>{'bytes_sent': 1200, 'bytesrcvd': '3400'},
        'totals': <String, dynamic>{'sum_bytes': '5000'},
      };

      final OnlineCounters? counters = extractNetworkCounters(payload);

      expect(counters, isNotNull);
      expect(counters!.bytesSent, 1200);
      expect(counters.bytesReceived, 3400);
      expect(counters.totalBytes, 5000);
    });

    test('returns null when no counters are present', () {
      final OnlineCounters? counters = extractNetworkCounters(<String, dynamic>{'foo': 'bar'});

      expect(counters, isNull);
    });
  });
}
