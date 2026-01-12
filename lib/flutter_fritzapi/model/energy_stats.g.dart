// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnergyStats _$EnergyStatsFromJson(Map<String, dynamic> json) => EnergyStats(
  sumDay: (json['sum_Day'] as num).toInt(),
  sumMonth: (json['sum_Month'] as num).toInt(),
  sumYear: (json['sum_Year'] as num).toInt(),
  deviceId: json['DeviceID'] as String,
  deviceConnectState: json['DeviceConnectState'] as String,
  deviceSwitchState: json['DeviceSwitchState'] as String,
  tabType: $enumDecode(_$TabTypeEnumMap, json['tabType']),
  currentDateInSec: json['CurrentDateInSec'] as String,
  requestResult: json['RequestResult'] as bool,
  energyStat: EnergyStat.fromJson(json['EnergyStat'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EnergyStatsToJson(EnergyStats instance) =>
    <String, dynamic>{
      'sum_Month': instance.sumMonth,
      'sum_Year': instance.sumYear,
      'sum_Day': instance.sumDay,
      'DeviceConnectState': instance.deviceConnectState,
      'DeviceID': instance.deviceId,
      'DeviceSwitchState': instance.deviceSwitchState,
      'tabType': _$TabTypeEnumMap[instance.tabType]!,
      'CurrentDateInSec': instance.currentDateInSec,
      'RequestResult': instance.requestResult,
      'EnergyStat': instance.energyStat.toJson(),
    };

const _$TabTypeEnumMap = {
  TabType.hour: 'hour',
  TabType.day: '24h',
  TabType.week: 'week',
  TabType.month: 'month',
  TabType.twoYears: '2years',
};

EnergyStat _$EnergyStatFromJson(Map<String, dynamic> json) => EnergyStat(
  level: (json['ebene'] as num).toInt(),
  amount: (json['anzahl'] as num).toInt(),
  timesType: (json['times_type'] as num).toInt(),
  values: (json['values'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$EnergyStatToJson(EnergyStat instance) =>
    <String, dynamic>{
      'ebene': instance.level,
      'anzahl': instance.amount,
      'times_type': instance.timesType,
      'values': instance.values,
    };
