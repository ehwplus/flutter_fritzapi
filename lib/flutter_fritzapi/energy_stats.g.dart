// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnergyStats _$EnergyStatsFromJson(Map<String, dynamic> json) => EnergyStats(
      sumDay: json['sum_Day'] as int,
      sumMonth: json['sum_Month'] as int,
      sumYear: json['sum_Year'] as int,
      deviceId: json['DeviceID'] as String,
      deviceConnectState: json['DeviceConnectState'] as String,
      deviceSwitchState: json['DeviceSwitchState'] as String,
      tabType: $enumDecode(_$TabTypeEnumMap, json['tabType']),
      currentDateInSec: json['CurrentDateInSec'] as int,
      requestResult: json['RequestResult'] as bool,
      energyStat:
          EnergyStat.fromJson(json['EnergyStat'] as Map<String, dynamic>),
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
  TabType.hours: 'hours',
  TabType.day: 'day',
  TabType.week: 'week',
  TabType.month: 'month',
  TabType.twoYears: 'twoYears',
};

EnergyStat _$EnergyStatFromJson(Map<String, dynamic> json) => EnergyStat(
      level: json['ebene'] as int,
      amount: json['anzahl'] as int,
      timesType: json['times_type'] as int,
      values: (json['values'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$EnergyStatToJson(EnergyStat instance) =>
    <String, dynamic>{
      'ebene': instance.level,
      'anzahl': instance.amount,
      'times_type': instance.timesType,
      'values': instance.values,
    };
