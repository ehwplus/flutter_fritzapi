// 1 Woche (4 Tageswerte à 6h)
// http://fritz.box/net/home_auto_query.lua
//   ?sid=6c07d631b2843403
//   &no_sidrenew=1
//   &command=EnergyStats_week&id=17&useajax=1&xhr=1&t1672084109143=nocache

// EnergyStats_24h
// http://fritz.box/net/home_auto_query.lua
//   ?sid=6c07d631b2843403
//   &no_sidrenew=1
//   &command=EnergyStats_24h&id=17&useajax=1&xhr=1&t1672083944869=nocache

import 'package:flutter_fritzapi/flutter_fritzapi.dart';

abstract class FritzHttpClient {

  String? getSessionId();

  /// http://fritz.box/net/home_auto_query.lua
  ///   ?sid=<sid>
  ///   &command=EnergyStats_<tabType>
  ///   &id=17
  ///   &xhr=1
  EnergyStats? getEnergyStats(String sessionId, HomeAutoQueryCommand command);

}

enum HomeAutoQueryCommand {
  EnergyStats_hour,
  EnergyStats_24h,
  EnergyStats_week,
  EnergyStats_month,
  EnergyStats_2years,
}