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

    test('parses clients with properties and nested ipv4 info', () {
      final Map<String, dynamic> entry1 = <String, dynamic>{
        'own_client_device': false,
        'type': 'wlan',
        'options': <String, dynamic>{'guest': false, 'editable': true, 'deleteable': true, 'disable': true},
        'properties': <Map<String, dynamic>>[
          <String, dynamic>{'txt': 'Mesh', 'link': '', 'class': 'nexus text'},
          <String, dynamic>{'txt': '2,4 GHz, 115 / 1 Mbit/s'},
          <String, dynamic>{'txt': '5 GHz, 1040 / 1404 Mbit/s'},
        ],
        'isTrusted': true,
        'UID': 'landev1',
        'state': <String, dynamic>{'class': 'led_green'},
        'port': 'WLAN',
        'name': 'FRITZ!Repeater 2400',
        'model': 'active',
        'classes': 'wlan',
        'url': 'http://192.168.178.254',
        'mac': 'AA:BB:CC:DD:EE:E9',
        'ipv4': <String, dynamic>{
          '_node': 'entry0',
          'addrtype': 'IPv4',
          'dhcp': 1,
          'lastused': 1768219136,
          'ip': '192.168.178.254',
        },
      };

      final Map<String, dynamic> entry2 = <String, dynamic>{
        'own_client_device': false,
        'type': 'wlan',
        'options': <String, dynamic>{'guest': false, 'editable': true, 'deleteable': true, 'disable': true},
        'properties': <Map<String, dynamic>>[
          <String, dynamic>{'txt': '2,4 GHz, 1 / 1 Mbit/s'},
        ],
        'UID': 'landev2',
        'state': <String, dynamic>{'class': 'globe_online'},
        'port': 'WLAN',
        'name': 'TP Tapo P115 (Waschmaschine)',
        'model': 'active',
        'classes': 'wlan',
        'url': 'http://192.168.178.23',
        'mac': 'AA:BB:CC:DD:EE:E8',
        'ipv4': <String, dynamic>{
          '_node': 'entry0',
          'addrtype': 'IPv4',
          'dhcp': 1,
          'lastused': 1768218480,
          'ip': '192.168.178.23',
        },
      };

      final List<WifiClient> clients = parseWifiClients(<String, dynamic>{
        'active': <Map<String, dynamic>>[entry1, entry2],
      });

      expect(clients.length, 2);
      expect(clients.first.ip, '192.168.178.254');
      expect(clients.first.radioChannel2_4, isNotNull);
      expect(clients.first.radioChannel5, isNotNull);
      expect(clients.first.radioChannel6, isNull);
      expect(clients.first.lastSeen, isNotNull);
    });
  });

  group('Network counters', () {
    test('extracts counters from nested payload', () {
      final Map<String, dynamic> payload = <String, dynamic>{
        'overview': <String, dynamic>{'bytes_sent': 1200, 'bytesrcvd': '3400'},
        'totals': <String, dynamic>{'sum_bytes': '5000'},
      };

      final NetworkCounters? counters = extractNetworkCounters(payload);

      expect(counters, isNotNull);
      expect(counters!.bytesSent, 1200);
      expect(counters.bytesReceived, 3400);
      expect(counters.totalBytes, 5000);
    });

    test('returns null when no counters are present', () {
      final NetworkCounters? counters = extractNetworkCounters(<String, dynamic>{'foo': 'bar'});

      expect(counters, isNull);
    });
  });
}
