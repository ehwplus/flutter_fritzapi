import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/devices.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/energy_stats.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/model/network_counters.dart';
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
  Future<OnlineCounters?> getOnlineCounters() async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final List<Uri> candidates = <Uri>[
      Uri.parse('$baseUrl/internet/inetstat_monitor.lua?sid=${sessionId!}&useajax=1'),
      Uri.parse('$baseUrl/internet/inetstat_monitor.lua?sid=${sessionId!}'),
      Uri.parse('$baseUrl/online-monitor/online-counter'),
    ];

    for (final Uri url in candidates) {
      try {
        final FritzApiResponse response = await get(url, headers: const <String, String>{});
        final Map<String, dynamic>? decoded = _tryDecodeJsonMap(response.body);
        if (decoded == null) {
          continue;
        }
        final OnlineCounters? counters = extractNetworkCounters(decoded);
        if (counters != null) {
          return counters;
        }
      } catch (error) {
        debugPrint('Failed to load online counters from ${url.path}: $error');
      }
    }

    return null;
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
    final Map<String, String> headers = {};
    final response = await get(url, headers: headers);

    try {
      return EnergyStats.fromJson(jsonDecode(response.body));
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<FritzApiResponse> get(Uri url, {Map<String, String>? headers});

  Future<FritzApiResponse> post(Uri url, {Map<String, String>? headers, required Map<String, String> body});
}

class FritzApiResponse {
  const FritzApiResponse({required this.statusCode, required this.body});

  final String body;

  final int statusCode;
}

enum HomeAutoQueryCommand { EnergyStats_24h, EnergyStats_week, EnergyStats_month, EnergyStats_2years }

/// Tries to decode a JSON object and returns `null` on failure.
Map<String, dynamic>? _tryDecodeJsonMap(String body) {
  try {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    // Ignore decode errors to allow caller to try alternative endpoints.
  }
  return null;
}

/// Extracts counters for bytes sent/received from the FRITZ!Box JSON response.
OnlineCounters? extractNetworkCounters(Map<String, dynamic> json) {
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
      for (final dynamic child in value) {
        walk(child);
      }
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

  return OnlineCounters(totalBytes: total, bytesSent: sent, bytesReceived: received, raw: json);
}

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
      final String name = _wifiClientName(entry);
      final String? ip = _asString(entry['ip'] ?? entry['ipv4']);
      final String? mac = _asString(entry['mac'] ?? entry['wlanMAC']);
      final String? connectionType = _asString(entry['type'] ?? entry['connectionType']);
      final bool isOnline = entry['active'] == true || entry['isActive'] == true || entry['connected'] == true;
      clients.add(
        WifiClient(name: name, ip: ip, mac: mac, connectionType: connectionType, isOnline: isOnline, raw: entry),
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
    entry['ipv4'],
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
