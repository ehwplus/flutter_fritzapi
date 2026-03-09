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

  group('Select xml values with namespaces', () {
    const soapResponse = '''
      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Body>
          <u:GetStatusInfoResponse xmlns:u="urn:dslforum-org:service:WANIPConnection:1">
            <NewUptime>12345</NewUptime>
          </u:GetStatusInfoResponse>
        </s:Body>
      </s:Envelope>
    ''';

    test('Parse NewUptime with namespace envelope', () async {
      final result = extractValueOfXmlTagIgnoringNamespace(
        xml: soapResponse,
        xmlTag: 'NewUptime',
      );
      expect(result, '12345');
    });
  });
}
