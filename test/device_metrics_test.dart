import 'package:flutter_fritzapi/flutter_fritzapi/model/devices.dart';
import 'package:test/test.dart';

void main() {
  group('Device metrics', () {
    test('parses temperature, humidity and power', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'type': 'SmartHomeDevice',
        'isDeletable': true,
        'id': 42,
        'masterConnectionState': 'CONNECTED',
        'displayName': 'Arbeitszimmer',
        'category': 'THERMOSTAT',
        'model': 'FRITZ!DECT 440',
        'units': <Map<String, dynamic>>[
          <String, dynamic>{
            'skills': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'SmartHomeThermostat',
                'temperature': <String, dynamic>{'celsius': 21.5},
                'humidity': <String, dynamic>{'relativeHumidity': 54},
              },
              <String, dynamic>{
                'type': 'SmartHomeSwitch',
                'powerConsumptionInWatt': '3.2',
              },
            ],
          },
        ],
      };

      final Device device = Device.fromJson(json);

      expect(device.temperatureCelsius, closeTo(21.5, 0.001));
      expect(device.humidityPercent, 54);
      expect(device.powerWatt, closeTo(3.2, 0.001));
      expect(device.capabilities.contains(DeviceCapability.energy), isTrue);
      expect(device.capabilities.contains(DeviceCapability.temperature), isTrue);
      expect(device.capabilities.contains(DeviceCapability.humidity), isTrue);
    });

    test('falls back to unknown category gracefully', () {
      final Device device = Device.fromJson(<String, dynamic>{
        'type': 'SmartHomeDevice',
        'isDeletable': true,
        'id': 99,
        'masterConnectionState': 'CONNECTED',
        'displayName': 'Unknown category device',
        'category': 'UNSUPPORTED_TYPE',
        'model': 'Some sensor',
      });

      expect(device.category, DeviceCategory.unknown);
      expect(device.capabilities, isEmpty);
    });
  });
}
