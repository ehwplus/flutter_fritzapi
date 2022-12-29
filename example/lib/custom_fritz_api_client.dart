import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_fritzapi/flutter_fritzapi.dart';

class CustomFritzApiClient extends FritzApiClient {
  CustomFritzApiClient({
    String baseUrl = 'http://fritz.box',
  }): super(baseUrl: baseUrl);

  @override
  Future<FritzApiResponse> get(Uri url, {Map<String, String>? headers}) async {
    final response = await http.get(url, headers: headers);
    final body = utf8.decode(response.bodyBytes);

    return FritzApiResponse(
      statusCode: response.statusCode,
      body: body,
    );
  }

  @override
  Future<FritzApiResponse> post(Uri url, {Map<String, String>? headers, required Map<String, String> body}) async {
    final response = await http.post(url, headers: headers, body: body);
    final responseBody = utf8.decode(response.bodyBytes);

    return FritzApiResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }

}