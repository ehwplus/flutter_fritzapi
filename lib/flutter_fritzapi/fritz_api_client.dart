import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_fritzapi/flutter_fritzapi.dart';

import 'encode_utf16le.dart';

abstract class FritzApiClient {

  FritzApiClient({
    this.baseUrl = 'http://fritz.box',
  });

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

  String? _extractValueOfXmlTag({required String xml, required String xmlTag}) {
    if (!xml.contains(xmlTag)) {
      return null;
    }
    final firstSplit = xml.split('<$xmlTag>')[1];
    final value = firstSplit.split('</''$xmlTag>')[0];
    return value;
  }

  Future<String?> _getChallenge() async {
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
    return _extractValueOfXmlTag(xml: challengeResponse.body, xmlTag: 'Challenge');
  }

  Future<String?> getSessionId({
    String username = 'fritz2672',
    required String password,
  }) async {
    // AVM documentation (German): https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/Session-ID_deutsch_13Nov18.pdf

    /*if (sessionId != null && sessionId.isNotEmpty && sessionId != '0000000000000000') {
      final isSessionIdValid = await get(Uri.parse('$baseUrl/login_sid.lua?sid=$sessionId'), headers: <String, String>{});
      return sessionId;
    }*/

    final challenge = await _getChallenge();

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
    final response = (await post(url, body: {
      'response': challengeResponse.toString(),
      'username': username,
    })).body;
    return sessionId = _extractValueOfXmlTag(xml: response, xmlTag: 'SID');
  }

  /// http://fritz.box/net/home_auto_query.lua
  ///   ?sid=<sid>
  ///   &command=EnergyStats_<tabType>
  ///   &id=17
  ///   &xhr=1
  Future<EnergyStats?> getEnergyStats({
    required HomeAutoQueryCommand command,
    required String deviceId,
  }) async {
    assert(sessionId != null && sessionId!.isNotEmpty, 'SessionId must not be null or empty');

    final url = Uri.parse('$baseUrl/net/home_auto_query.lua?sid=${sessionId!}&command=${command.name}&id=$deviceId&xhr=1');
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

  const FritzApiResponse({
    required this.statusCode,
    required this.body,
  });

  final String body;

  final int statusCode;

}

enum HomeAutoQueryCommand {
  EnergyStats_hour,
  EnergyStats_24h,
  EnergyStats_week,
  EnergyStats_month,
  EnergyStats_2years,
}