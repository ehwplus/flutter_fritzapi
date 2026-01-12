import 'dart:convert';

import 'package:flutter_fritzapi/flutter_fritzapi/model/energy_stats.dart';
import 'package:flutter_fritzapi/flutter_fritzapi/utils/xml_select.dart';
import 'package:test/test.dart';

void main() {
  const xml = '''
      <SessionInfo>
        <SID>0000000000000000</SID>
        <Challenge>85e33062</Challenge>
        <BlockTime>0</BlockTime>
        <Rights/>
        <Users>
          <User last="1">fritz1234</User>
        </Users>
      </SessionInfo>
  ''';

  group('Select xml values', () {
    test('Parse challenge', () async {
      final result = extractValueOfXmlTag(xml: xml, xmlTag: 'Challenge');
      expect(result, '85e33062');
    });

    test('Parse SID', () async {
      final result = extractValueOfXmlTag(xml: xml, xmlTag: 'SID');
      expect(result, '0000000000000000');
    });

    test('Parse User', () async {
      final result = extractValueOfXmlTag(xml: xml, xmlTag: 'User');
      expect(result, 'fritz1234');
    });
  });
}
