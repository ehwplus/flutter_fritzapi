import 'dart:convert';

import 'package:flutter_fritzapi/flutter_fritzapi.dart';
import 'package:test/test.dart';

class _FakeFritzApiClient extends FritzApiClient {
  _FakeFritzApiClient(this.responses) : super(baseUrl: 'http://fritz.box');

  final Map<String, FritzApiResponse> responses;

  @override
  Future<FritzApiResponse> get(Uri url, {Map<String, String>? headers}) async {
    return responses[url.toString()] ?? const FritzApiResponse(statusCode: 404, body: '{}');
  }

  @override
  Future<FritzApiResponse> post(Uri url, {Map<String, String>? headers, required Map<String, String> body}) async {
    return const FritzApiResponse(statusCode: 404, body: '{}');
  }
}

Map<String, FritzApiResponse> _buildResponses({
  required bool isOn,
  required List<double> temperatures,
  required List<double> humidities,
  int intervalSeconds = 900,
}) {
  const String unitsUrl = 'http://fritz.box/api/v0/smarthome/overview/units';
  const String unitUrl = 'http://fritz.box/api/v0/smarthome/overview/units/unit-1';
  final List<Map<String, dynamic>> unitsBody = <Map<String, dynamic>>[
    <String, dynamic>{
      'UID': 'unit-1',
      'deviceId': '42',
      'name': 'Test Unit',
      'onOffInterface': <String, dynamic>{'active': isOn},
    },
  ];
  final Map<String, dynamic> statistics = <String, dynamic>{};
  if (temperatures.isNotEmpty) {
    statistics['temperatures'] = <Map<String, dynamic>>[
      <String, dynamic>{'period': 'day', 'interval': intervalSeconds, 'values': temperatures},
    ];
  }
  if (humidities.isNotEmpty) {
    statistics['humidities'] = <Map<String, dynamic>>[
      <String, dynamic>{'period': 'day', 'interval': intervalSeconds, 'values': humidities},
    ];
  }
  final Map<String, dynamic> unitBody = <String, dynamic>{
    'UID': 'unit-1',
    'statistics': statistics,
    'onOffInterface': <String, dynamic>{'active': isOn},
  };
  return <String, FritzApiResponse>{
    unitsUrl: FritzApiResponse(statusCode: 200, body: jsonEncode(unitsBody)),
    unitUrl: FritzApiResponse(statusCode: 200, body: jsonEncode(unitBody)),
  };
}

Future<EnvironmentReadings> _loadReadings(_FakeFritzApiClient client, {bool enableJumpFilter = true}) async {
  client.sessionId = '123';
  final Map<SensorHistoryInterval, EnvironmentReadings> result = await client.getEnvironmentHistory(
    42,
    ranges: <SensorHistoryInterval>[SensorHistoryInterval.day],
    enableJumpFilter: enableJumpFilter,
  );
  return result[SensorHistoryInterval.day] ?? const EnvironmentReadings(entries: <EnvironmentReading>[]);
}

List<double> _temperatureValues(EnvironmentReadings readings) {
  return readings.entries.map((EnvironmentReading entry) => entry.temperatureCelsius).whereType<double>().toList();
}

List<double> _humidityValues(EnvironmentReadings readings) {
  return readings.entries.map((EnvironmentReading entry) => entry.humidityPercent).whereType<double>().toList();
}

void main() {
  group('Environment history jump filter', () {
    test('filters plateau before jump when device is on', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(isOn: true, temperatures: <double>[4.5, 4.5, 4.5, 23.5, 23.4], humidities: const <double>[]),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_temperatureValues(readings), <double>[23.5, 23.4]);
    });

    test('filters plateau after jump when device is off', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(isOn: false, temperatures: <double>[23.5, 23.4, 4.5, 4.5, 4.5], humidities: const <double>[]),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_temperatureValues(readings), <double>[23.5, 23.4]);
    });

    test('uses last jump that has a plateau on the relevant side', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(
          isOn: true,
          temperatures: <double>[19.5, 12, 4.5, 4.5, 4.5, 23.5, 23.5, 23, 22, 19, 5],
          humidities: const <double>[],
        ),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_temperatureValues(readings), <double>[19.5, 23.5, 23.5, 23, 22, 19]);
    });

    test('uses last jump that has a plateau on the relevant side', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(
          isOn: true,
          temperatures: <double>[
            23.5,
            23,
            23.5,
            23,
            22.5,
            22,
            21,
            19.5,
            12,
            4.5,
            4.5,
            4.5,
            23.5,
            23.5,
            23,
            22,
            19,
            4.5,
            4.5,
          ],
          humidities: const <double>[],
        ),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_temperatureValues(readings), <double>[23.5, 23, 23.5, 23, 22.5, 22, 21, 19.5, 23.5, 23.5, 23, 22, 19]);
    });

    test('filters humidity plateau with default threshold', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(isOn: false, temperatures: const <double>[], humidities: <double>[50, 49, 15, 15, 15]),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_humidityValues(readings), <double>[50, 49]);
    });

    test('does not filter when interval is not 15 minutes', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(
          isOn: true,
          temperatures: <double>[4.5, 4.5, 4.5, 23.5, 23.4],
          humidities: const <double>[],
          intervalSeconds: 1800,
        ),
      );

      final EnvironmentReadings readings = await _loadReadings(client);

      expect(_temperatureValues(readings), <double>[4.5, 4.5, 4.5, 23.5, 23.4]);
    });

    test('can disable jump filter', () async {
      final _FakeFritzApiClient client = _FakeFritzApiClient(
        _buildResponses(isOn: true, temperatures: <double>[4.5, 4.5, 4.5, 23.5, 23.4], humidities: const <double>[]),
      );

      final EnvironmentReadings readings = await _loadReadings(client, enableJumpFilter: false);

      expect(_temperatureValues(readings), <double>[4.5, 4.5, 4.5, 23.5, 23.4]);
    });
  });
}
