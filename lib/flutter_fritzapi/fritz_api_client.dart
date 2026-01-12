import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/devices.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/energy_stats.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/network_counters.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/sensor_history.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/wifi_client.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/utils/xml_select.dart';

import 'utils/encode_utf16le.dart';

abstract class FritzApiClient {
  FritzApiClient({this.baseUrl = 'http://fritz.box'});

  final String baseUrl;

  /// A 64-bit number represented by 16 hex digits. It is assigned at login and
  /// must be kept for the duration of the session. A program should only use
  /// one FRITZ!Box should only use one session ID for each FRITZ!Box, as the
  /// number of sessions for a FRITZ!Box is limited. FRITZ!Box is limited.
  ///
  /// The session ID has a validity of 60 minutes after assignment. The validity
  /// period is automatically extended when the FRITZ!Box is actively accessed.
  ///
  /// The session ID 0 (000000000000) is always invalid.
  String? sessionId;

  Future<bool> isConnectedWithFritzBox() async {
    try {
      final challengeResponse = await get(Uri.parse('$baseUrl/login_sid.lua'));
      final challenge = extractValueOfXmlTag(xml: challengeResponse.body, xmlTag: 'Challenge');
      return challenge != null;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String?>> _getChallenge() async {
    /// Der Wert <challenge> kann aus der Datei login_sid.lua ausgelesen werden
    /*
      <SessionInfo>
        <SID>0000000000000000</SID>
        <Challenge>85e33062</Challenge>
        <BlockTime>0</BlockTime>
        <Rights/>
        <Users>
          <User last="1">fritz1234</User>
        </Users>
      </SessionInfo>
     */
    final challengeResponse = await get(Uri.parse('$baseUrl/login_sid.lua'));
    final challenge = extractValueOfXmlTag(xml: challengeResponse.body, xmlTag: 'Challenge');
    final user = extractValueOfXmlTag(xml: challengeResponse.body, xmlTag: 'User');

    return {'user': user, 'challenge': challenge};
  }

  Future<String?> getSessionId({String? username, required String password}) async {
    // AVM documentation (German): https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/Session-ID_deutsch_13Nov18.pdf

    /*if (sessionId != null && sessionId.isNotEmpty && sessionId != '0000000000000000') {
      final isSessionIdValid = await get(Uri.parse('$baseUrl/login_sid.lua?sid=$sessionId'), headers: <String, String>{});
      return sessionId;
    }*/

    final challengeMap = await _getChallenge();
    final challenge = challengeMap['challenge'];
    final user = challengeMap['user'];

    /// <md5> ist der MD5 (32 Hexzeichen mit Kleinbuchstaben) von
    /// <challenge>-<klartextpassword>
    final challengeResponse = StringBuffer()
      ..write(challenge)
      ..write('-')
      /*
            md5 = hashlib.md5()
            ..update(challenge.encode('utf-16le'))
            ..update('-'.encode('utf-16le'))
            ..update(password.encode('utf-16le'))
            response = challenge + '-' + md5.hexdigest()
       */
      // require('crypto').createHash('md5').update(Buffer(challenge+'-'+password, 'UTF-16LE')).digest('hex')
      ..write(md5.convert(encodeUtf16le('$challenge-$password')).toString());
    final url = Uri.parse('$baseUrl/login_sid.lua');
    if ((username ?? user) == null) {
      return null;
    }
    final response = (await post(
      url,
      body: {'response': challengeResponse.toString(), 'username': username ?? user!},
    )).body;
    final sessionId = extractValueOfXmlTag(xml: response, xmlTag: 'SID');
    if (sessionId != '0000000000000000') {
      this.sessionId = sessionId;
      return sessionId;
    }
    return null;
  }

  Future<Devices> getDevices() async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final url = Uri.parse('$baseUrl/data.lua');
    final body = <String, String>{'sid': sessionId!, 'xhrId': 'all', 'xhr': '1', 'page': 'sh_dev'};
    final result = await post(url, body: body);
    final devices = Devices.fromJson(jsonDecode(result.body));

    return devices;
  }

  /// Reads the current WAN counters (bytes sent/received) from the FRITZ!Box UI.
  Future<NetworkCounters?> getOnlineCounters() async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final List<Uri> candidates = <Uri>[
      Uri.parse('$baseUrl/online-monitor/counter'),
      Uri.parse('$baseUrl/online-monitor/counter&sid=${sessionId!}'),
      Uri.parse('$baseUrl/online-monitor/counter&sid=${sessionId!}&xhr=1'),
      Uri.parse('$baseUrl/online-monitor/counter&sid=${sessionId!}&useajax=1'),
    ];

    for (final Uri url in candidates) {
      try {
        FritzApiResponse response;
        if (url.path.endsWith('data.lua')) {
          response = await post(
            url,
            headers: const <String, String>{},
            body: <String, String>{'sid': sessionId!, 'xhr': '1', 'page': 'overview'},
          );
        } else {
          response = await get(url, headers: const <String, String>{});
        }
        print('${url.toString()}: ${response.body}');
        final Map<String, dynamic>? decoded = _tryDecodeJsonMap(response.body);
        if (decoded == null) {
          continue;
        }
        final NetworkCounters? counters = extractNetworkCounters(decoded);
        if (counters != null) {
          return counters;
        }
      } catch (error) {
        debugPrint('Failed to load online counters from ${url.path}: $error');
      }
    }

    return null;
  }

  /// Retrieves power history across several ranges.
  Future<PowerHistory?> getPowerHistory(int deviceId, {List<HistoryRange> ranges = HistoryRange.values}) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');
    EnergyStats? day;
    EnergyStats? week;
    EnergyStats? month;
    EnergyStats? twoYears;
    final Map<HistoryRange, Map<String, dynamic>> raw = <HistoryRange, Map<String, dynamic>>{};

    for (final HistoryRange range in ranges) {
      final Map<String, dynamic>? payload = await _getHomeAutoStats(
        command: _sensorCommand(SensorStatType.temperature, range, prefixOverride: 'EnergyStats'),
        deviceId: deviceId,
      );
      if (payload == null) {
        continue;
      }
      final Map<String, dynamic> normalized = _normalizeEnergyPayload(payload);
      raw[range] = normalized;
      EnergyStats? stats;
      try {
        stats = EnergyStats.fromJson(normalized);
      } catch (error, stack) {
        debugPrint('Failed to parse EnergyStats for range $range: $error\n$stack\nPayload: $normalized');
      }
      if (stats == null) {
        continue;
      }
      switch (range) {
        case HistoryRange.day:
          day = stats;
          break;
        case HistoryRange.week:
          week = stats;
          break;
        case HistoryRange.month:
          month = stats;
          break;
        case HistoryRange.twoYears:
          twoYears = stats;
          break;
      }
    }

    final PowerHistory history = PowerHistory(day: day, week: week, month: month, twoYears: twoYears, raw: raw);
    return history.isEmpty ? null : history;
  }

  /// Retrieves temperature history for a device for the requested ranges.
  Future<Map<HistoryRange, SensorHistory>> getTemperatureHistory(
    int deviceId, {
    List<HistoryRange> ranges = const <HistoryRange>[HistoryRange.day],
  }) => _getSensorHistory(deviceId: deviceId, ranges: ranges, type: SensorStatType.temperature);

  /// Retrieves humidity history for a device for the requested ranges.
  Future<Map<HistoryRange, SensorHistory>> getHumidityHistory(
    int deviceId, {
    List<HistoryRange> ranges = const <HistoryRange>[HistoryRange.day],
  }) => _getSensorHistory(deviceId: deviceId, ranges: ranges, type: SensorStatType.humidity);

  /// Returns a list of Wi‑Fi clients reported by the FRITZ!Box.
  Future<List<WifiClient>> getWifiClients() async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final Uri url = Uri.parse('$baseUrl/data.lua');
    final FritzApiResponse result = await post(
      url,
      body: <String, String>{'sid': sessionId!, 'xhrId': 'all', 'xhr': '1', 'page': 'netDev'},
    );
    final Map<String, dynamic>? parsed = _tryDecodeJsonMap(result.body);
    if (parsed == null) {
      return const <WifiClient>[];
    }
    final dynamic data = parsed['data'];
    if (data is! Map<String, dynamic>) {
      return const <WifiClient>[];
    }
    return parseWifiClients(data);
  }

  /// http://fritz.box/net/home_auto_query.lua
  ///   ?sid=<sid>
  ///   &command=EnergyStats_<tabType>
  ///   &id=17
  ///   &xhr=1
  Future<EnergyStats?> getEnergyStats({required HomeAutoQueryCommand command, required int deviceId}) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final url = Uri.parse(
      '$baseUrl/net/home_auto_query.lua?sid=${sessionId!}&command=${command.name}&id=$deviceId&xhr=1',
    );
    final response = await get(url, headers: const <String, String>{});
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final Map<String, dynamic> normalized = _normalizeEnergyPayload(decoded);
    try {
      return EnergyStats.fromJson(normalized);
    } catch (error, stack) {
      Error.throwWithStackTrace(
        StateError('Failed to parse energy stats for device $deviceId: $error\nPayload: $normalized'),
        stack,
      );
    }
  }

  Future<FritzApiResponse> get(Uri url, {Map<String, String>? headers});

  Future<FritzApiResponse> post(Uri url, {Map<String, String>? headers, required Map<String, String> body});

  HomeAutoQueryCommand? _energyCommandForRange(HistoryRange range) {
    switch (range) {
      case HistoryRange.day:
        return HomeAutoQueryCommand.EnergyStats_24h;
      case HistoryRange.week:
        return HomeAutoQueryCommand.EnergyStats_week;
      case HistoryRange.month:
        return HomeAutoQueryCommand.EnergyStats_month;
      case HistoryRange.twoYears:
        return HomeAutoQueryCommand.EnergyStats_2years;
    }
  }

  /// Tries to decode a JSON object and returns `null` on failure.
  Map<String, dynamic>? _tryDecodeJsonMap(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore primary decode errors and try to salvage JSON below.
    }
    // Attempt to salvage JSON by trimming leading JS assignments or non-JSON data.
    final int firstBrace = body.indexOf('{');
    if (firstBrace != -1) {
      try {
        final String trimmed = body.substring(firstBrace);
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Continue to next fallback.
      }
    }
    final int firstBracket = body.indexOf('[');
    if (firstBracket != -1) {
      try {
        final String trimmed = body.substring(firstBracket);
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Ignore.
      }
    }
    return null;
  }

  Future<Map<HistoryRange, SensorHistory>> _getSensorHistory({
    required int deviceId,
    required List<HistoryRange> ranges,
    required SensorStatType type,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final Map<HistoryRange, SensorHistory> result = <HistoryRange, SensorHistory>{};
    for (final HistoryRange range in ranges) {
      final String command = _sensorCommand(type, range);
      final Map<String, dynamic>? payload = await _getHomeAutoStats(command: command, deviceId: deviceId);
      if (payload == null) {
        continue;
      }
      final SensorHistory? parsed = _parseSensorHistory(payload, type: type, range: range);
      if (parsed != null) {
        result[range] = parsed;
      }
    }
    return result;
  }

  String _sensorCommand(SensorStatType type, HistoryRange range, {String? prefixOverride}) {
    final String prefix =
        prefixOverride ??
        switch (type) {
          SensorStatType.temperature => 'TemperatureStats',
          SensorStatType.humidity => 'HumidityStats',
        };
    final String suffix = switch (range) {
      HistoryRange.day => '24h',
      HistoryRange.week => 'week',
      HistoryRange.month => 'month',
      HistoryRange.twoYears => '2years',
    };
    return '${prefix}_$suffix';
  }

  Future<Map<String, dynamic>?> _getHomeAutoStats({
    required String command,
    required int deviceId,
    String? overrideBaseUrl,
    String? overrideSessionId,
  }) async {
    final String sid = overrideSessionId ?? sessionId ?? '';
    assert(sid.isNotEmpty, 'SessionId must not be null or empty');
    final Uri url = Uri.parse(
      '${overrideBaseUrl ?? baseUrl}/net/home_auto_query.lua?sid=$sid&command=$command&id=$deviceId&xhr=1',
    );
    final FritzApiResponse response = await get(url, headers: const <String, String>{});
    return _tryDecodeJsonMap(response.body);
  }

  Map<String, dynamic> _normalizeEnergyPayload(Map<String, dynamic> input) {
    final Map<String, dynamic> output = Map<String, dynamic>.from(input);

    void parseIntKey(String key) {
      final dynamic value = output[key];
      if (value is String) {
        final int? parsed = int.tryParse(value);
        if (parsed != null) {
          output[key] = parsed;
        }
      }
    }

    parseIntKey('sum_Month');
    parseIntKey('sum_Year');
    parseIntKey('sum_Day');

    if (output['EnergyStat'] is Map<String, dynamic>) {
      final Map<String, dynamic> energyStat = Map<String, dynamic>.from(output['EnergyStat'] as Map<String, dynamic>);
      void parseEnergyInt(String key) {
        final dynamic value = energyStat[key];
        if (value is String) {
          final int? parsed = int.tryParse(value);
          if (parsed != null) {
            energyStat[key] = parsed;
          }
        }
      }

      parseEnergyInt('ebene');
      parseEnergyInt('anzahl');
      parseEnergyInt('times_type');
      if (energyStat['values'] is List) {
        energyStat['values'] = (energyStat['values'] as List)
            .map((dynamic v) => v is String ? int.tryParse(v) ?? v : v)
            .toList();
      }
      output['EnergyStat'] = energyStat;
    }

    return output;
  }

  SensorHistory? _parseSensorHistory(
    Map<String, dynamic> json, {
    required SensorStatType type,
    required HistoryRange range,
  }) {
    Map<String, dynamic>? statMap;
    for (final String key in <String>['TemperatureStat', 'HumidityStat', 'EnergyStat', 'stat', 'data']) {
      if (json[key] is Map<String, dynamic>) {
        statMap = Map<String, dynamic>.from(json[key] as Map<String, dynamic>);
        break;
      }
    }
    statMap ??= json;
    final List<double> values = _extractNumericList(statMap['values'] ?? statMap['data'] ?? statMap['list']);
    if (values.isEmpty) {
      return null;
    }
    final int? intervalSeconds = _asInt(statMap['times_type'] ?? statMap['interval'] ?? statMap['timeframe']);
    final int? level = _asInt(statMap['ebene'] ?? statMap['level']);
    return SensorHistory(
      type: type,
      range: range,
      values: values,
      intervalSeconds: intervalSeconds,
      level: level,
      raw: json,
    );
  }

  List<double> _extractNumericList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((dynamic v) {
            if (v is num) {
              return v.toDouble();
            }
            if (v is String) {
              return double.tryParse(v);
            }
            return null;
          })
          .whereType<double>()
          .toList();
    }
    return const <double>[];
  }
}

class FritzApiResponse {
  const FritzApiResponse({required this.statusCode, required this.body});

  final String body;

  final int statusCode;
}

enum HomeAutoQueryCommand { EnergyStats_24h, EnergyStats_week, EnergyStats_month, EnergyStats_2years }

/// Parses clients from the `/data.lua?page=netDev` response structure.
List<WifiClient> parseWifiClients(Map<String, dynamic> data) {
  final List<WifiClient> clients = <WifiClient>[];
  const List<String> preferredKeys = <String>['active', 'passive', 'anmd'];

  void parseList(dynamic value) {
    if (value is! List) {
      return;
    }
    for (final dynamic entry in value) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final Map<String, dynamic>? ipv4Map = entry['ipv4'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(entry['ipv4'] as Map<String, dynamic>)
          : null;
      final String name = _wifiClientName(entry);
      final String? ip = _asString(entry['ip'] ?? ipv4Map?['ip'] ?? entry['ipv4']);
      final String? mac = _asString(entry['mac'] ?? entry['wlanMAC']);
      final String? connectionType = _asString(entry['type'] ?? entry['connectionType']);
      final bool isOnline = entry['active'] == true || entry['isActive'] == true || entry['connected'] == true;
      final DateTime? lastSeen = _asDateTime(
        entry['lastused'] ?? entry['lastSeen'] ?? entry['lastUsed'] ?? ipv4Map?['lastused'],
      );
      final properties2_4 = (entry['properties'] as List<dynamic>)
          .where((dynamic item) {
            return item.containsKey('txt') && (item['txt'].startsWith('2,4 GHz'));
          })
          .map((item) => item['txt']);
      final properties5 = (entry['properties'] as List<dynamic>)
          .where((dynamic item) {
            return item.containsKey('txt') && (item['txt'].startsWith('5 GHz'));
          })
          .map((item) => item['txt']);
      final properties6 = (entry['properties'] as List<dynamic>)
          .where((dynamic item) {
            return item.containsKey('txt') && (item['txt'].startsWith('6 GHz'));
          })
          .map((item) => item['txt']);
      clients.add(
        WifiClient(
          name: name,
          ip: ip,
          mac: mac,
          connectionType: connectionType,
          isOnline: isOnline,
          raw: entry,
          lastSeen: lastSeen,
          radioChannel2_4: properties2_4.isEmpty ? null : properties2_4.first,
          radioChannel5: properties5.isEmpty ? null : properties5.first,
          radioChannel6: properties6.isEmpty ? null : properties6.first,
        ),
      );
    }
  }

  for (final String key in preferredKeys) {
    parseList(data[key]);
  }

  data.forEach((String key, dynamic value) {
    if (!preferredKeys.contains(key)) {
      parseList(value);
    }
  });

  return clients;
}

String _wifiClientName(Map<String, dynamic> entry) {
  final List<dynamic> candidates = <dynamic>[
    entry['name'],
    (entry['details'] is Map<String, dynamic>) ? (entry['details'] as Map<String, dynamic>)['name'] : null,
    entry['ip'],
    entry['ipv4'] is Map<String, dynamic> ? (entry['ipv4'] as Map<String, dynamic>)['ip'] : entry['ipv4'],
  ];
  for (final dynamic candidate in candidates) {
    final String? value = _asString(candidate);
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return 'Unknown device';
}

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

int? _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  final int? raw = _asInt(value);
  if (raw == null) {
    return null;
  }
  // Heuristic: treat >= 1e12 as milliseconds, otherwise seconds.
  final DateTime dateTime = raw > 1000000000000
      ? DateTime.fromMillisecondsSinceEpoch(raw)
      : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  return dateTime.toUtc();
}

/// Extracts counters for bytes sent/received from the FRITZ!Box JSON response.
NetworkCounters? extractNetworkCounters(Map<String, dynamic> json) {
  final Map<String, int> totals = <String, int>{};

  void walk(dynamic value) {
    if (value is Map<String, dynamic>) {
      value.forEach((String key, dynamic child) {
        final String lower = key.toLowerCase();
        final int? parsed = _asInt(child);
        final bool isCounterKey =
            lower.contains('bytes_sent') ||
            lower.contains('bytesrcvd') ||
            lower.contains('bytes_received') ||
            lower.contains('bytesin') ||
            lower.contains('bytesout') ||
            lower == 'sum_bytes' ||
            lower.contains('totalbytes') ||
            lower == 'sent' ||
            lower == 'rcvd' ||
            lower == 'received';
        if (parsed != null && isCounterKey) {
          totals[lower] = parsed;
        } else {
          walk(child);
        }
      });
    } else if (value is Iterable) {
      value.forEach(walk);
    }
  }

  walk(json);

  int? _firstMatching(bool Function(String key) predicate) {
    for (final MapEntry<String, int> entry in totals.entries) {
      if (predicate(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  final int sent = _firstMatching((String key) => key.contains('sent') || key.contains('out')) ?? 0;
  final int received =
      _firstMatching((String key) => key.contains('rcvd') || key.contains('received') || key.contains('in')) ?? 0;
  final int total = _firstMatching((String key) => key.contains('sum') || key.contains('total')) ?? (sent + received);

  if (total == 0 && sent == 0 && received == 0) {
    return null;
  }

  return NetworkCounters(totalBytes: total, bytesSent: sent, bytesReceived: received, raw: json);
}
