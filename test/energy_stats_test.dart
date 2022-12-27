import 'dart:convert';

import 'package:flutter_fritzapi/flutter_fritzapi/energy_stats.dart';
import 'package:test/test.dart';

void main() {
  const jsonDay = '''
{
 "DeviceConnectState": "2",
 "sum_Month": 14387,
 "sum_Year": 172645,
 "sum_Day": 473,
 "DeviceID": "17",
 "DeviceSwitchState": "1",
 "EnergyStat": {
  "ebene": 2,
  "anzahl": 96,
  "values": [3, 9, 0, 8, 4, 4, 7, 0, 8, 8, 2, 5, 9, 0, 8, 0, 8, 2, 7, 4, 4, 7, 0, 9, 3, 5, 7, 2, 8, 0, 8, 1, 8, 0, 8, 5, 3, 8, 3, 6, 5, 3, 9, 0, 8, 0, 8, 0, 8, 5, 3, 8, 0, 8, 1, 8, 1, 7, 4, 5, 7, 2, 8, 0, 8, 1, 8, 3, 5, 9, 0, 8, 0, 8, 4, 4, 8, 0, 8, 3, 5, 8, 0, 8, 3, 5, 8, 0, 9, 0, 8, 6, 3, 8, 0, 9],
  "times_type": 900,
  "ID": 17
 },
 "tabType": "24h",
 "CurrentDateInSec": "1672083945",
 "RequestResult": true
}
  ''';

  const jsonWeek = '''
{
 "DeviceConnectState": "2",
 "sum_Month": 14387,
 "sum_Year": 172645,
 "sum_Day": 473,
 "DeviceID": "17",
 "DeviceSwitchState": "1",
 "EnergyStat": {
  "ebene": 3,
  "anzahl": 28,
  "values": [56, 113, 111, 112, 123, 120, 117, 109, 123, 121, 121, 112, 114, 119, 110, 111, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  "times_type": 21600,
  "ID": 17
 },
 "tabType": "week",
 "CurrentDateInSec": "1672084109",
 "RequestResult": true
}
  ''';

  group('Parse json results', () {
    test('Parse day', () async {
      final result = EnergyStats.fromJson(jsonDecode(jsonDay));
      expect(result.energyStat.values.length, 96);
    });

    test('Parse week', () async {
      final result = EnergyStats.fromJson(jsonDecode(jsonWeek));
      expect(result.energyStat.values.length, 28);
    });
  });
}
