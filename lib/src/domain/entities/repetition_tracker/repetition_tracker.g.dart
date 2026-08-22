// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repetition_tracker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepetitionTracker _$RepetitionTrackerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RepetitionTracker', json, ($checkedConvert) {
      final val = RepetitionTracker(
        id: $checkedConvert('id', (v) => v as String?),
        callSignatures: $checkedConvert(
          'callSignatures',
          (v) => Map<String, int>.from(v as Map),
        ),
        recentCalls: $checkedConvert(
          'recentCalls',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RepetitionTrackerToJson(RepetitionTracker instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callSignatures': instance.callSignatures,
      'recentCalls': instance.recentCalls,
    };
