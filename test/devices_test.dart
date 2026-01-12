import 'package:flutter_fritzapi/flutter_fritzapi/model/devices.dart';
import 'package:test/test.dart';

void main() {
  const jsonDevices = {
    'pid': 'sh_dev',
    'hide': {
      'shareUsb': true,
      'liveTv': true,
      'dectRdio': true,
      'dectMoniEx': true,
      'rss': true,
      'ssoSet': true,
      'dectMail': true,
      'mobile': true,
      'liveImg': true,
    },
    'time': [],
    'data': {
      'devices': [
        {
          'type': 'SmartHomeDevice',
          'isDeletable': true,
          'id': 16,
          'masterConnectionState': 'CONNECTED',
          'displayName': 'Wohnzimmerheizung',
          'category': 'THERMOSTAT',
          'units': [
            {
              'type': 'THERMOSTAT',
              'id': 16,
              'displayName': 'Wohnzimmerheizung',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 302',
                'id': 16,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '13979 0342035',
                'displayName': 'Wohnzimmerheizung',
              },
              'skills': [
                {
                  'type': 'SmartHomeThermostat',
                  'presets': [
                    {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                    {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                  ],
                  'nextChange': {
                    'description': {
                      'action': 'TARGET_TEMPERATURE',
                      'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                    },
                    'timeSetting': {'startDate': '2022-12-28', 'startTime': '06:30:40'},
                  },
                  'temperatureDropDetection': {'doNotHeatOffsetInMinutes': 10, 'sensitivity': 5, 'isWindowOpen': false},
                  'targetTemp': 16,
                  'timeControl': {
                    'isEnabled': true,
                    'timeSchedules': [
                      {
                        'isEnabled': false,
                        'kind': 'REPETITIVE',
                        'name': 'HOLIDAYS',
                        'actions': [
                          {
                            'isEnabled': false,
                            'timeSetting': {
                              'startDate': '2019-12-26',
                              'endTime': '00:00:00',
                              'startTime': '00:00:00',
                              'repetition': 'YEARLY',
                              'endDate': '2019-01-09',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'HOLIDAY_TEMPERATURE', 'temperature': 127.5},
                            },
                          },
                          {
                            'isEnabled': false,
                            'timeSetting': {
                              'startDate': '2019-12-26',
                              'endTime': '00:00:00',
                              'startTime': '00:00:00',
                              'repetition': 'YEARLY',
                              'endDate': '2019-01-09',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'HOLIDAY_TEMPERATURE', 'temperature': 127.5},
                            },
                          },
                          {
                            'isEnabled': false,
                            'timeSetting': {
                              'startDate': '2019-12-26',
                              'endTime': '00:00:00',
                              'startTime': '00:00:00',
                              'repetition': 'YEARLY',
                              'endDate': '2019-01-09',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'HOLIDAY_TEMPERATURE', 'temperature': 127.5},
                            },
                          },
                          {
                            'isEnabled': false,
                            'timeSetting': {
                              'startDate': '2019-12-26',
                              'endTime': '00:00:00',
                              'startTime': '00:00:00',
                              'repetition': 'YEARLY',
                              'endDate': '2019-01-09',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'HOLIDAY_TEMPERATURE', 'temperature': 127.5},
                            },
                          },
                        ],
                      },
                      {
                        'isEnabled': true,
                        'kind': 'REPETITIVE',
                        'name': 'SUMMER_TIME',
                        'actions': [
                          {
                            'isEnabled': true,
                            'timeSetting': {'startDate': '2019-06-01', 'repetition': 'YEARLY', 'endDate': '2019-08-31'},
                            'description': {'action': 'SET_OFF'},
                          },
                        ],
                      },
                      {
                        'isEnabled': true,
                        'kind': 'WEEKLY_TIMETABLE',
                        'name': 'TEMPERATURE',
                        'actions': [
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '07:30:00'},
                              'dayOfWeek': 'SUN',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '11:30:00'},
                              'dayOfWeek': 'SUN',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '17:00:00'},
                              'dayOfWeek': 'SUN',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '23:00:00'},
                              'dayOfWeek': 'SUN',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '06:30:00'},
                              'dayOfWeek': 'MON',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '08:00:00'},
                              'dayOfWeek': 'MON',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '18:00:00'},
                              'dayOfWeek': 'MON',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '22:00:00'},
                              'dayOfWeek': 'MON',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '06:30:00'},
                              'dayOfWeek': 'TUE',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '08:00:00'},
                              'dayOfWeek': 'TUE',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '18:00:00'},
                              'dayOfWeek': 'TUE',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '22:00:00'},
                              'dayOfWeek': 'TUE',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '06:30:00'},
                              'dayOfWeek': 'WED',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '08:00:00'},
                              'dayOfWeek': 'WED',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '18:00:00'},
                              'dayOfWeek': 'WED',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '22:00:00'},
                              'dayOfWeek': 'WED',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '06:30:00'},
                              'dayOfWeek': 'THU',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '08:00:00'},
                              'dayOfWeek': 'THU',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '18:00:00'},
                              'dayOfWeek': 'THU',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '22:00:00'},
                              'dayOfWeek': 'THU',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '06:30:00'},
                              'dayOfWeek': 'FRI',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '08:00:00'},
                              'dayOfWeek': 'FRI',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '18:00:00'},
                              'dayOfWeek': 'FRI',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '22:00:00'},
                              'dayOfWeek': 'FRI',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '07:30:00'},
                              'dayOfWeek': 'SAT',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '11:30:00'},
                              'dayOfWeek': 'SAT',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '17:00:00'},
                              'dayOfWeek': 'SAT',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'UPPER_TEMPERATURE', 'temperature': 20},
                            },
                          },
                          {
                            'isEnabled': true,
                            'timeSetting': {
                              'time': {'startTime': '23:00:00'},
                              'dayOfWeek': 'SAT',
                            },
                            'description': {
                              'action': 'SET_TEMPERATURE',
                              'presetTemperature': {'name': 'LOWER_TEMPERATURE', 'temperature': 16},
                            },
                          },
                        ],
                      },
                    ],
                  },
                  'holidayActive': false,
                  'mode': 'TARGET_TEMPERATURE',
                  'summerActive': false,
                  'usedTempSensor': {
                    'type': 'TEMPERATURE_SENSOR',
                    'id': 16,
                    'displayName': 'Wohnzimmerheizung',
                    'skills': [
                      {'offset': 0, 'type': 'SmartHomeTemperatureSensor', 'currentInCelsius': 19},
                    ],
                    'actorIdentificationNumber': '13979 0342035',
                  },
                },
              ],
              'interactionControls': [
                {'devControlName': 'BUTTON', 'isLocked': false},
                {'devControlName': 'EXTERNAL', 'isLocked': false},
              ],
              'actorIdentificationNumber': '13979 0342035',
            },
            {
              'type': 'TEMPERATURE_SENSOR',
              'id': 16,
              'displayName': 'Wohnzimmerheizung',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 302',
                'id': 16,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '13979 0342035',
                'displayName': 'Wohnzimmerheizung',
              },
              'skills': [
                {'offset': 0, 'type': 'SmartHomeTemperatureSensor', 'currentInCelsius': 19},
              ],
              'actorIdentificationNumber': '13979 0342035',
            },
            {
              'type': 'BATTERY',
              'id': 16,
              'displayName': 'Wohnzimmerheizung',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 302',
                'id': 16,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '13979 0342035',
                'displayName': 'Wohnzimmerheizung',
              },
              'skills': [
                {'chargeLevelInPercent': 100, 'type': 'SmartHomeBattery'},
              ],
              'actorIdentificationNumber': '13979 0342035',
            },
          ],
          'firmwareVersion': {'search': false, 'current': '05.07', 'update': false, 'running': false},
          'model': 'FRITZ!DECT 302',
          'isEditable': true,
          'manufacturer': {'name': 'AVM'},
          'pushService': {'mailAddress': '', 'unitSettings': [], 'isEnabled': false},
          'actorIdentificationNumber': '13979 0342035',
        },
        {
          'type': 'SmartHomeDevice',
          'isDeletable': true,
          'id': 17,
          'masterConnectionState': 'CONNECTED',
          'displayName': 'Kühlschrank',
          'category': 'SOCKET',
          'units': [
            {
              'type': 'TEMPERATURE_SENSOR',
              'id': 17,
              'displayName': 'Kühlschrank',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 200',
                'id': 17,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '11630 0324586',
                'displayName': 'Kühlschrank',
              },
              'skills': [
                {'offset': 0, 'type': 'SmartHomeTemperatureSensor', 'currentInCelsius': 24.5},
              ],
              'actorIdentificationNumber': '11630 0324586',
            },
            {
              'type': 'MICROPHONE',
              'id': 17,
              'displayName': 'Kühlschrank',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 200',
                'id': 17,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '11630 0324586',
                'displayName': 'Kühlschrank',
              },
              'skills': [
                {
                  'type': 'SmartHomeEvent',
                  'timeControl': {
                    'isEnabled': false,
                    'timeSchedules': [
                      {
                        'isEnabled': false,
                        'kind': 'COUNTDOWN',
                        'name': 'COUNTDOWN',
                        'actions': [
                          {
                            'isEnabled': false,
                            'timeSetting': {'durationInSeconds': 0},
                            'description': {'action': 'SET_ON'},
                          },
                        ],
                      },
                      {
                        'isEnabled': false,
                        'kind': 'REPETITIVE',
                        'actions': [
                          {
                            'isEnabled': false,
                            'timeSetting': {
                              'endTime': '00:00:00',
                              'startTime': '00:00:00',
                              'startDate': '2019-01-01',
                              'endDate': '2019-01-01',
                            },
                            'desription': {'action': 'SET_ON'},
                          },
                        ],
                      },
                    ],
                  },
                  'isEnabled': false,
                  'trigger': {'action': 'SOUND'},
                  'event': {
                    'description': {'action': 'SET_OFF'},
                    'targets': [],
                  },
                },
              ],
              'actorIdentificationNumber': '11630 0324586',
            },
            {
              'type': 'SOCKET',
              'id': 17,
              'displayName': 'Kühlschrank',
              'device': {
                'masterConnectionState': 'CONNECTED',
                'type': 'SmartHomeDevice',
                'model': 'FRITZ!DECT 200',
                'id': 17,
                'manufacturer': {'name': 'AVM'},
                'actorIdentificationNumber': '11630 0324586',
                'displayName': 'Kühlschrank',
              },
              'skills': [
                {
                  'type': 'SmartHomeMultimeter',
                  'voltageInVolt': 228.904,
                  'powerConsumptionInWatt': 80.39,
                  'powerPerHour': 2357,
                  'electricCurrentInAmpere': 0.4049,
                },
                {
                  'type': 'SmartHomeSocket',
                  'ledState': 'ON',
                  'powerLossOption': 'LAST',
                  'timeControl': {
                    'isEnabled': false,
                    'timeSchedules': [
                      {
                        'isEnabled': false,
                        'kind': 'COUNTDOWN',
                        'name': 'COUNTDOWN',
                        'actions': [
                          {
                            'isEnabled': false,
                            'timeSetting': {'durationInSeconds': 0},
                            'name': 'SET_OFF',
                          },
                        ],
                      },
                    ],
                  },
                  'standby': {'isEnabled': false, 'seconds': 0, 'powerInWatt': 0},
                },
                {
                  'state': 'ON',
                  'type': 'SmartHomeSwitch',
                  'timeControl': {'isEnabled': false, 'timeSchedules': []},
                },
              ],
              'interactionControls': [
                {'devControlName': 'BUTTON', 'isLocked': false},
                {'devControlName': 'EXTERNAL', 'isLocked': false},
              ],
              'actorIdentificationNumber': '11630 0324586',
            },
          ],
          'firmwareVersion': {'search': false, 'current': '04.25', 'update': false, 'running': false},
          'model': 'FRITZ!DECT 200',
          'isEditable': true,
          'manufacturer': {'name': 'AVM'},
          'pushService': {
            'mailAddress': '',
            'unitSettings': [],
            'isEnabled': false,
            'switchTrigger': false,
            'energyStatistic': 'MIN10',
          },
          'actorIdentificationNumber': '11630 0324586',
        },
      ],
    },
    'sid': '62fa82bdc8ef52cd',
  };

  group('Parse json results', () {
    test('Parse day', () async {
      final result = Devices.fromJson(jsonDevices);
      expect(result.devices.length, 2);
      expect(result.getConnectedDevices().length, 1);
    });
  });
}
