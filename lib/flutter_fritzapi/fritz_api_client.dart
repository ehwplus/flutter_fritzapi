import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/device.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/devices.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/environment_readings.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/energy_stats.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/network_counters.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/sensor_history.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/wifi_client.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/utils/xml_select.dart';

import 'utils/encode_utf16le.dart';

abstract class FritzApiClient {
  FritzApiClient({this.baseUrl = 'http://fritz.box'});

  final String baseUrl;
  String? _smarthomeBasePath;

  static const List<String> _smarthomeBasePathCandidates = <String>['/api/v0', '/webservices', ''];

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
  Future<PowerHistory?> getPowerHistory(
    int deviceId, {
    List<SensorHistoryInterval> ranges = SensorHistoryInterval.values,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');
    EnergyStats? day;
    EnergyStats? week;
    EnergyStats? month;
    EnergyStats? twoYears;
    final Map<SensorHistoryInterval, Map<String, dynamic>> raw = <SensorHistoryInterval, Map<String, dynamic>>{};

    for (final SensorHistoryInterval range in ranges) {
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
        case SensorHistoryInterval.day:
          day = stats;
          break;
        case SensorHistoryInterval.week:
          week = stats;
          break;
        case SensorHistoryInterval.month:
          month = stats;
          break;
        case SensorHistoryInterval.twoYears:
          twoYears = stats;
          break;
      }
    }

    final PowerHistory history = PowerHistory(day: day, week: week, month: month, twoYears: twoYears, raw: raw);
    return history.isEmpty ? null : history;
  }

  /// Retrieves temperature history for a device for the requested ranges.
  Future<Map<SensorHistoryInterval, SensorHistory>> getTemperatureHistory(
    int deviceId, {
    List<SensorHistoryInterval> ranges = const <SensorHistoryInterval>[SensorHistoryInterval.day],
  }) async {
    final Map<SensorHistoryInterval, SensorHistory>? smarthome = await _getSmarthomeSensorHistory(
      deviceId: deviceId,
      ranges: ranges,
      type: SensorStatType.temperature,
    );
    if (smarthome != null && smarthome.isNotEmpty) {
      return smarthome;
    }
    return _getSensorHistory(deviceId: deviceId, ranges: ranges, type: SensorStatType.temperature);
  }

  /// Retrieves humidity history for a device for the requested ranges.
  Future<Map<SensorHistoryInterval, SensorHistory>> getHumidityHistory(
    int deviceId, {
    List<SensorHistoryInterval> ranges = const <SensorHistoryInterval>[SensorHistoryInterval.day],
  }) async {
    final Map<SensorHistoryInterval, SensorHistory>? smarthome = await _getSmarthomeSensorHistory(
      deviceId: deviceId,
      ranges: ranges,
      type: SensorStatType.humidity,
    );
    if (smarthome != null && smarthome.isNotEmpty) {
      return smarthome;
    }
    return _getSensorHistory(deviceId: deviceId, ranges: ranges, type: SensorStatType.humidity);
  }

  /// Retrieves temperature/humidity readings with timestamps for the requested ranges.
  /// Timestamps are derived from the statistics interval and anchored to the FRITZ!Box time if present,
  /// otherwise the local time at request execution.
  Future<Map<SensorHistoryInterval, EnvironmentReadings>> getEnvironmentHistory(
    int deviceId, {
    List<SensorHistoryInterval> ranges = const <SensorHistoryInterval>[SensorHistoryInterval.day],
  }) async {
    final Map<SensorHistoryInterval, EnvironmentReadings>? smarthome = await _getSmarthomeEnvironmentHistory(
      deviceId: deviceId,
      ranges: ranges,
    );
    if (smarthome != null && smarthome.isNotEmpty) {
      return smarthome;
    }
    final Map<SensorHistoryInterval, SensorHistory> temperature = await _getSensorHistory(
      deviceId: deviceId,
      ranges: ranges,
      type: SensorStatType.temperature,
    );
    final Map<SensorHistoryInterval, SensorHistory> humidity = await _getSensorHistory(
      deviceId: deviceId,
      ranges: ranges,
      type: SensorStatType.humidity,
    );
    return _mergeLegacyEnvironmentHistory(
      temperature: temperature,
      humidity: humidity,
      ranges: ranges,
    );
  }

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

  HomeAutoQueryCommand? _energyCommandForRange(SensorHistoryInterval range) {
    switch (range) {
      case SensorHistoryInterval.day:
        return HomeAutoQueryCommand.EnergyStats_24h;
      case SensorHistoryInterval.week:
        return HomeAutoQueryCommand.EnergyStats_week;
      case SensorHistoryInterval.month:
        return HomeAutoQueryCommand.EnergyStats_month;
      case SensorHistoryInterval.twoYears:
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

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      // Ignore primary decode errors and try to salvage JSON below.
    }
    final int firstBrace = body.indexOf('{');
    if (firstBrace != -1) {
      try {
        final String trimmed = body.substring(firstBrace);
        return jsonDecode(trimmed);
      } catch (_) {
        // Continue to next fallback.
      }
    }
    final int firstBracket = body.indexOf('[');
    if (firstBracket != -1) {
      try {
        final String trimmed = body.substring(firstBracket);
        return jsonDecode(trimmed);
      } catch (_) {
        // Ignore.
      }
    }
    return null;
  }

  Future<Map<SensorHistoryInterval, SensorHistory>> _getSensorHistory({
    required int deviceId,
    required List<SensorHistoryInterval> ranges,
    required SensorStatType type,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final Map<SensorHistoryInterval, SensorHistory> result = <SensorHistoryInterval, SensorHistory>{};
    for (final SensorHistoryInterval range in ranges) {
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

  Future<Map<SensorHistoryInterval, SensorHistory>?> _getSmarthomeSensorHistory({
    required int deviceId,
    required List<SensorHistoryInterval> ranges,
    required SensorStatType type,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final List<Map<String, dynamic>> units = await _getSmarthomeUnits();
    if (units.isEmpty) {
      return null;
    }
    final String? unitUid = await _resolveSmarthomeUnitUid(deviceId, units: units);
    if (unitUid == null || unitUid.isEmpty) {
      return null;
    }
    final Map<String, dynamic>? unit = await _getSmarthomeUnit(unitUid);
    if (unit == null) {
      return null;
    }
    final Map<SensorHistoryInterval, SensorHistory> parsed = _parseSmarthomeSensorHistory(
      unit,
      type: type,
      ranges: ranges,
    );
    return parsed.isEmpty ? null : parsed;
  }

  Future<Map<SensorHistoryInterval, EnvironmentReadings>?> _getSmarthomeEnvironmentHistory({
    required int deviceId,
    required List<SensorHistoryInterval> ranges,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final List<Map<String, dynamic>> units = await _getSmarthomeUnits();
    if (units.isEmpty) {
      return null;
    }
    final String? unitUid = await _resolveSmarthomeUnitUid(deviceId, units: units);
    if (unitUid == null || unitUid.isEmpty) {
      return null;
    }
    final Map<String, dynamic>? unit = await _getSmarthomeUnit(unitUid);
    if (unit == null) {
      return null;
    }
    final Map<SensorHistoryInterval, EnvironmentReadings> parsed = _parseSmarthomeEnvironmentHistory(
      unit,
      ranges: ranges,
    );
    return parsed.isEmpty ? null : parsed;
  }

  String _sensorCommand(SensorStatType type, SensorHistoryInterval range, {String? prefixOverride}) {
    final String prefix =
        prefixOverride ??
        switch (type) {
          SensorStatType.temperature => 'TemperatureStats',
          SensorStatType.humidity => 'HumidityStats',
        };
    final String suffix = switch (range) {
      SensorHistoryInterval.day => '24h',
      SensorHistoryInterval.week => 'week',
      SensorHistoryInterval.month => 'month',
      SensorHistoryInterval.twoYears => '2years',
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

  Map<String, String> _smarthomeHeaders() {
    final String sid = sessionId ?? '';
    return <String, String>{'Authorization': 'AVM-SID $sid', 'AVM-SID': sid, 'Accept': 'application/json'};
  }

  Uri _buildSmarthomeUri(String basePath, String path) {
    final String normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final String normalizedBasePath = basePath.isEmpty ? '' : (basePath.startsWith('/') ? basePath : '/$basePath');
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBaseUrl$normalizedBasePath$normalizedPath');
  }

  Future<dynamic> _getSmarthomeData(String path) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final List<String> candidates = _smarthomeBasePath != null
        ? <String>[_smarthomeBasePath!]
        : _smarthomeBasePathCandidates;
    for (final String basePath in candidates) {
      final Uri uri = _buildSmarthomeUri(basePath, path);
      try {
        final FritzApiResponse response = await get(uri, headers: _smarthomeHeaders());
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic decoded = _tryDecodeJson(response.body);
          if (decoded != null) {
            _smarthomeBasePath = basePath;
            return decoded;
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          final dynamic decoded = _tryDecodeJson(response.body);
          if (decoded != null) {
            _smarthomeBasePath = basePath;
            return decoded;
          }
        }
      } catch (error) {
        debugPrint('Failed to load Smarthome REST data from $uri: $error');
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getSmarthomeUnits() async {
    final dynamic decoded = await _getSmarthomeData('/smarthome/overview/units');
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().map((Map<String, dynamic> item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }
    if (decoded is Map<String, dynamic>) {
      final dynamic list = decoded['units'] ?? decoded['data'] ?? decoded['items'];
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().map((Map<String, dynamic> item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> _getSmarthomeUnit(String uid) async {
    final String encodedUid = Uri.encodeComponent(uid);
    final dynamic decoded = await _getSmarthomeData('/smarthome/overview/units/$encodedUid');
    if (decoded is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Future<String?> _resolveSmarthomeUnitUid(int deviceId, {List<Map<String, dynamic>>? units}) async {
    final List<Map<String, dynamic>> resolvedUnits = units ?? await _getSmarthomeUnits();
    if (resolvedUnits.isEmpty) {
      return null;
    }

    final String? direct = _matchUnitUidByTokens(resolvedUnits, <String>[deviceId.toString()]);
    if (direct != null) {
      return direct;
    }

    Device? device;
    try {
      final Devices devices = await getDevices();
      device = devices.devices.firstWhere((Device candidate) => candidate.id == deviceId);
    } catch (_) {
      device = null;
    }
    if (device == null) {
      return null;
    }

    final List<String> tokens = _collectDeviceIdentifiers(device);
    final String? match = _matchUnitUidByTokens(resolvedUnits, tokens);
    if (match != null) {
      return match;
    }

    return _matchUnitUidByName(resolvedUnits, device.displayName);
  }

  List<String> _collectDeviceIdentifiers(Device device) {
    final Set<String> tokens = <String>{device.id.toString()};
    void addToken(dynamic value) {
      final String? parsed = _asString(value);
      if (parsed != null && parsed.trim().isNotEmpty) {
        tokens.add(parsed.trim());
      }
    }

    final Map<String, dynamic>? raw = device.raw;
    if (raw != null) {
      for (final String key in <String>[
        'ain',
        'identifier',
        'deviceIdentifier',
        'deviceId',
        'id',
        'uid',
        'UID',
        'deviceUid',
        'parentUid',
        'groupUid',
      ]) {
        if (raw.containsKey(key)) {
          addToken(raw[key]);
        }
      }
      final dynamic nestedDevice = raw['device'];
      if (nestedDevice is Map<String, dynamic>) {
        for (final String key in <String>['ain', 'identifier', 'deviceIdentifier', 'deviceId', 'id', 'uid', 'UID']) {
          if (nestedDevice.containsKey(key)) {
            addToken(nestedDevice[key]);
          }
        }
      }
      final dynamic units = raw['units'];
      if (units is List) {
        for (final dynamic unit in units) {
          if (unit is Map<String, dynamic>) {
            for (final String key in <String>['uid', 'UID', 'ain', 'identifier', 'deviceUid']) {
              if (unit.containsKey(key)) {
                addToken(unit[key]);
              }
            }
          }
        }
      }
    }

    return tokens.toList(growable: false);
  }

  String? _matchUnitUidByTokens(List<Map<String, dynamic>> units, Iterable<String> tokens) {
    final Set<String> normalizedTokens = tokens
        .map(_normalizeIdentifier)
        .where((String token) => token.isNotEmpty)
        .toSet();
    if (normalizedTokens.isEmpty) {
      return null;
    }
    for (final Map<String, dynamic> unit in units) {
      final Set<String> unitIds = _smarthomeUnitIdentifiers(
        unit,
      ).map(_normalizeIdentifier).where((String token) => token.isNotEmpty).toSet();
      if (unitIds.any(normalizedTokens.contains)) {
        return _smarthomeUnitUid(unit);
      }
    }
    return null;
  }

  String? _matchUnitUidByName(List<Map<String, dynamic>> units, String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    final String normalizedName = name.trim().toLowerCase();
    final List<Map<String, dynamic>> matches = units.where((Map<String, dynamic> unit) {
      final String? unitName = _asString(unit['name']);
      return unitName != null && unitName.trim().toLowerCase() == normalizedName;
    }).toList();
    if (matches.isEmpty) {
      return null;
    }
    if (matches.length == 1) {
      return _smarthomeUnitUid(matches.first);
    }
    final List<Map<String, dynamic>> nonGroups = matches
        .where((Map<String, dynamic> unit) => unit['isGroupUnit'] != true)
        .toList();
    if (nonGroups.length == 1) {
      return _smarthomeUnitUid(nonGroups.first);
    }
    return null;
  }

  String _normalizeIdentifier(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  String? _smarthomeUnitUid(Map<String, dynamic> unit) {
    return _asString(unit['UID'] ?? unit['uid']);
  }

  Iterable<String> _smarthomeUnitIdentifiers(Map<String, dynamic> unit) sync* {
    for (final String key in <String>['UID', 'uid', 'deviceUid', 'parentUid', 'groupUid', 'ain', 'deviceId', 'id']) {
      final String? value = _asString(unit[key]);
      if (value != null && value.isNotEmpty) {
        yield value;
      }
    }
  }

  Map<SensorHistoryInterval, SensorHistory> _parseSmarthomeSensorHistory(
    Map<String, dynamic> unit, {
    required SensorStatType type,
    required List<SensorHistoryInterval> ranges,
  }) {
    final Map<SensorHistoryInterval, SensorHistory> result = <SensorHistoryInterval, SensorHistory>{};
    final dynamic stats = unit['statistics'];
    if (stats is! Map<String, dynamic>) {
      return result;
    }
    final String key = type == SensorStatType.temperature ? 'temperatures' : 'humidities';
    final dynamic entries = stats[key] ?? stats['temperature'] ?? stats['humidity'];
    if (entries is! List) {
      return result;
    }
    for (final dynamic entry in entries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final String? period = _asString(entry['period']);
      final SensorHistoryInterval? range = _smarthomePeriodToRange(period);
      if (range == null || !ranges.contains(range)) {
        continue;
      }
      final String? state = _asString(entry['statisticsState']);
      if (state != null && _isInvalidStatisticsState(state)) {
        continue;
      }
      final List<double> values = _extractNumericList(entry['values']);
      if (values.isEmpty) {
        continue;
      }
      result[range] = SensorHistory(
        type: type,
        range: range,
        values: values,
        intervalSeconds: _asInt(entry['interval']),
        level: _asInt(entry['level']),
        raw: <String, dynamic>{'unit': unit, 'stat': entry},
      );
    }
    return result;
  }

  Map<SensorHistoryInterval, EnvironmentReadings> _parseSmarthomeEnvironmentHistory(
    Map<String, dynamic> unit, {
    required List<SensorHistoryInterval> ranges,
  }) {
    final Map<SensorHistoryInterval, EnvironmentReadings> result = <SensorHistoryInterval, EnvironmentReadings>{};
    final dynamic stats = unit['statistics'];
    if (stats is! Map<String, dynamic>) {
      return result;
    }
    final List<dynamic> tempEntries =
        (stats['temperatures'] is List) ? (stats['temperatures'] as List) : const <dynamic>[];
    final List<dynamic> humidityEntries =
        (stats['humidities'] is List) ? (stats['humidities'] as List) : const <dynamic>[];
    if (tempEntries.isEmpty && humidityEntries.isEmpty) {
      return result;
    }

    for (final SensorHistoryInterval range in ranges) {
      final Map<String, dynamic>? tempEntry = _findSmarthomeStatEntry(tempEntries, range: range);
      final Map<String, dynamic>? humidityEntry = _findSmarthomeStatEntry(humidityEntries, range: range);
      final EnvironmentReadings? readings = _mergeSmarthomeEntries(
        range: range,
        temperatureEntry: tempEntry,
        humidityEntry: humidityEntry,
      );
      if (readings != null && !readings.isEmpty) {
        result[range] = readings;
      }
    }

    return result;
  }

  Map<String, dynamic>? _findSmarthomeStatEntry(List<dynamic> entries, {required SensorHistoryInterval range}) {
    for (final dynamic entry in entries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final SensorHistoryInterval? entryRange = _smarthomePeriodToRange(_asString(entry['period']));
      if (entryRange == range) {
        final String? state = _asString(entry['statisticsState']);
        if (state != null && _isInvalidStatisticsState(state)) {
          return null;
        }
        return Map<String, dynamic>.from(entry);
      }
    }
    return null;
  }

  EnvironmentReadings? _mergeSmarthomeEntries({
    required SensorHistoryInterval range,
    Map<String, dynamic>? temperatureEntry,
    Map<String, dynamic>? humidityEntry,
  }) {
    if (temperatureEntry == null && humidityEntry == null) {
      return null;
    }
    final Map<DateTime, _EnvironmentReadingBuilder> builders = <DateTime, _EnvironmentReadingBuilder>{};
    final DateTime now = DateTime.now();
    if (temperatureEntry != null) {
      final List<double> values = _extractNumericList(temperatureEntry['values']);
      final int? intervalSeconds = _resolveIntervalSeconds(
        _asInt(temperatureEntry['interval']),
        range: range,
        count: values.length,
      );
      _appendSeriesToBuilders(
        builders,
        values: values,
        intervalSeconds: intervalSeconds,
        referenceTime: now,
        isTemperature: true,
        raw: temperatureEntry,
      );
    }
    if (humidityEntry != null) {
      final List<double> values = _extractNumericList(humidityEntry['values']);
      final int? intervalSeconds = _resolveIntervalSeconds(
        _asInt(humidityEntry['interval']),
        range: range,
        count: values.length,
      );
      _appendSeriesToBuilders(
        builders,
        values: values,
        intervalSeconds: intervalSeconds,
        referenceTime: now,
        isTemperature: false,
        raw: humidityEntry,
      );
    }
    return _buildersToReadings(builders);
  }

  SensorHistoryInterval? _smarthomePeriodToRange(String? period) {
    if (period == null) {
      return null;
    }
    switch (period.toLowerCase()) {
      case 'day':
      case '24h':
        return SensorHistoryInterval.day;
      case 'week':
        return SensorHistoryInterval.week;
      case 'month':
        return SensorHistoryInterval.month;
      case 'year':
      case '2years':
      case 'twoyears':
        return SensorHistoryInterval.twoYears;
    }
    return null;
  }

  bool _isInvalidStatisticsState(String state) {
    switch (state.toLowerCase()) {
      case 'invalid':
      case 'error':
      case 'unavailable':
        return true;
    }
    return false;
  }

  Map<SensorHistoryInterval, EnvironmentReadings> _mergeLegacyEnvironmentHistory({
    required Map<SensorHistoryInterval, SensorHistory> temperature,
    required Map<SensorHistoryInterval, SensorHistory> humidity,
    required List<SensorHistoryInterval> ranges,
  }) {
    final Map<SensorHistoryInterval, EnvironmentReadings> result = <SensorHistoryInterval, EnvironmentReadings>{};
    for (final SensorHistoryInterval range in ranges) {
      final SensorHistory? tempHistory = temperature[range];
      final SensorHistory? humidityHistory = humidity[range];
      final EnvironmentReadings? readings = _mergeLegacySensorHistories(
        range: range,
        temperature: tempHistory,
        humidity: humidityHistory,
      );
      if (readings != null && !readings.isEmpty) {
        result[range] = readings;
      }
    }
    return result;
  }

  EnvironmentReadings? _mergeLegacySensorHistories({
    required SensorHistoryInterval range,
    SensorHistory? temperature,
    SensorHistory? humidity,
  }) {
    if (temperature == null && humidity == null) {
      return null;
    }
    final Map<DateTime, _EnvironmentReadingBuilder> builders = <DateTime, _EnvironmentReadingBuilder>{};
    if (temperature != null) {
      final DateTime referenceTime = _resolveLegacyReferenceTime(temperature.raw) ?? DateTime.now();
      final int? intervalSeconds = _resolveIntervalSeconds(
        temperature.intervalSeconds,
        range: range,
        count: temperature.values.length,
      );
      _appendSeriesToBuilders(
        builders,
        values: temperature.values,
        intervalSeconds: intervalSeconds,
        referenceTime: referenceTime,
        isTemperature: true,
        raw: temperature.raw,
      );
    }
    if (humidity != null) {
      final DateTime referenceTime = _resolveLegacyReferenceTime(humidity.raw) ?? DateTime.now();
      final int? intervalSeconds = _resolveIntervalSeconds(
        humidity.intervalSeconds,
        range: range,
        count: humidity.values.length,
      );
      _appendSeriesToBuilders(
        builders,
        values: humidity.values,
        intervalSeconds: intervalSeconds,
        referenceTime: referenceTime,
        isTemperature: false,
        raw: humidity.raw,
      );
    }
    return _buildersToReadings(builders);
  }

  DateTime? _resolveLegacyReferenceTime(Map<String, dynamic> raw) {
    final int? seconds = _asInt(raw['CurrentDateInSec'] ?? raw['currentDateInSec'] ?? raw['currentDate']);
    if (seconds != null && seconds > 0) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    final int? millis = _asInt(raw['CurrentDateInMSec'] ?? raw['currentDateInMSec']);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  int? _resolveIntervalSeconds(int? interval, {required SensorHistoryInterval range, required int count}) {
    if (interval != null && interval > 0) {
      return interval;
    }
    if (count <= 0) {
      return null;
    }
    final int totalSeconds = switch (range) {
      SensorHistoryInterval.day => 86400,
      SensorHistoryInterval.week => 7 * 86400,
      SensorHistoryInterval.month => 30 * 86400,
      SensorHistoryInterval.twoYears => 365 * 2 * 86400,
    };
    final int derived = (totalSeconds / count).round();
    return derived > 0 ? derived : null;
  }

  void _appendSeriesToBuilders(
    Map<DateTime, _EnvironmentReadingBuilder> builders, {
    required List<double> values,
    required int? intervalSeconds,
    required DateTime referenceTime,
    required bool isTemperature,
    Object? raw,
  }) {
    if (values.isEmpty || intervalSeconds == null || intervalSeconds <= 0) {
      return;
    }
    final DateTime roundedReference = _roundDown(referenceTime, intervalSeconds);
    final int length = values.length;
    final DateTime start = roundedReference.subtract(Duration(seconds: intervalSeconds * (length - 1)));
    for (int i = 0; i < length; i++) {
      final DateTime dt = start.add(Duration(seconds: intervalSeconds * i));
      final _EnvironmentReadingBuilder builder = builders.putIfAbsent(
        dt,
        () => _EnvironmentReadingBuilder(dt),
      );
      if (isTemperature) {
        builder.temperatureCelsius = values[i];
      } else {
        builder.humidityPercent = values[i];
      }
      if (raw != null) {
        builder.addRaw(raw);
      }
    }
  }

  DateTime _roundDown(DateTime value, int intervalSeconds) {
    if (intervalSeconds <= 0) {
      return value;
    }
    final int intervalMs = intervalSeconds * 1000;
    final int ms = value.millisecondsSinceEpoch;
    final int rounded = ms - (ms % intervalMs);
    return DateTime.fromMillisecondsSinceEpoch(rounded, isUtc: value.isUtc);
  }

  EnvironmentReadings _buildersToReadings(Map<DateTime, _EnvironmentReadingBuilder> builders) {
    if (builders.isEmpty) {
      return const EnvironmentReadings(entries: <EnvironmentReading>[]);
    }
    final List<_EnvironmentReadingBuilder> sorted = builders.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final List<EnvironmentReading> entries = sorted
        .map(
          (builder) => EnvironmentReading(
            dateTime: builder.dateTime.toIso8601String(),
            temperatureCelsius: builder.temperatureCelsius,
            humidityPercent: builder.humidityPercent,
            raw: builder.raw,
          ),
        )
        .toList();
    return EnvironmentReadings(entries: entries);
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
    required SensorHistoryInterval range,
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

class _EnvironmentReadingBuilder {
  _EnvironmentReadingBuilder(this.dateTime);

  final DateTime dateTime;
  double? temperatureCelsius;
  double? humidityPercent;
  final List<Object?> _raw = <Object?>[];

  Object? get raw {
    if (_raw.isEmpty) {
      return null;
    }
    if (_raw.length == 1) {
      return _raw.first;
    }
    return List<Object?>.unmodifiable(_raw);
  }

  void addRaw(Object value) {
    _raw.add(value);
  }
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
