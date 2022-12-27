import 'package:json_annotation/json_annotation.dart';

part 'energy_stats.g.dart';

/// The result of a FRITZ!DECT 200 for a HTTP request:
/// http://fritz.box/net/home_auto_query.lua
///   ?sid=<sid>
///   &command=EnergyStats_<tabType>
///   &id=17
///   &xhr=1
@JsonSerializable(explicitToJson: true)
class EnergyStats {

  const EnergyStats({
    required this.sumDay,
    required this.sumMonth,
    required this.sumYear,
    required this.deviceId,
    required this.deviceConnectState,
    required this.deviceSwitchState,
    required this.tabType,
    required this.currentDateInSec,
    required this.requestResult,
    required this.energyStat,
  });

  /// Example: 14387
  @JsonKey(name: 'sum_Month')
  final int sumMonth;

  /// Example: 172645
  @JsonKey(name: 'sum_Year')
  final int sumYear;

  /// Example: 473
  @JsonKey(name: 'sum_Day')
  final int sumDay;

  /// The connection state of the device, where "2" means connected. Other
  /// states are unknown. TODO: What other states are possible?
  /// Example: "2"
  @JsonKey(name: 'DeviceConnectState')
  final String deviceConnectState;

  /// Identifier for this FRITZ!DECT device that seems to be a fix id that does
  /// not change.
  /// Example: "17"
  @JsonKey(name: 'DeviceID')
  final String deviceId;

  /// Example: "1"
  @JsonKey(name: 'DeviceSwitchState')
  final String deviceSwitchState;

  /// Values: {"hour", "24h", "week", "month", "2years"}
  @JsonKey(name: 'tabType')
  final TabType tabType;

  /// Current time in millis since epoch, e.g. "1672093500"
  @JsonKey(name: 'CurrentDateInSec')
  final int currentDateInSec;

  /// TODO: Unclear what this boolean value means.
  /// true or false
  @JsonKey(name: 'RequestResult')
  final bool requestResult;

  @JsonKey(name: 'EnergyStat')
  final EnergyStat energyStat;

  factory EnergyStats.fromJson(Map<String, dynamic> json) =>
      _$EnergyStatsFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyStatsToJson(this);

}

enum TabType {
  hour,
  @JsonValue('24h')
  day,
  week,
  month,
  @JsonValue('2years')
  twoYears,
}

@JsonSerializable(explicitToJson: true)
class EnergyStat {

  const EnergyStat({
    required this.level,
    required this.amount,
    required this.timesType,
    required this.values,
  });

  /// The level from detailed to coarse, from 0 to 5. In German, "ebene".
  /// - hour = level 0
  /// - ?? = level 1 // TODO: What is [tabType] for level 1?
  /// - 24h = level 2
  /// - week = level 3
  /// - month = level 4
  /// - 2years = level 5
  @JsonKey(name: 'ebene')
  final int level;

  /// The number of data values within this EnergyStat
  @JsonKey(name: 'anzahl')
  final int amount;

  /// The length of each value in seconds.
  /// - For 24h: 900s, 15 minute values, 4 per hour, 96 in total
  /// - For week: 21600s, 6 hour values, 4 per day
  /// - For month: 86400s, a value for each day of the month
  @JsonKey(name: 'times_type')
  final int timesType;

  /// The values of this EnergyStat
  @JsonKey(name: 'values')
  final List<int> values;

  factory EnergyStat.fromJson(Map<String, dynamic> json) =>
      _$EnergyStatFromJson(json);

  Map<String, dynamic> toJson() => _$EnergyStatToJson(this);

}