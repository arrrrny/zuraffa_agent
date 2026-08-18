// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compaction_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompactionSummary _$CompactionSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompactionSummary', json, ($checkedConvert) {
      final val = CompactionSummary(
        decisions: $checkedConvert(
          'decisions',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        toolNames: $checkedConvert(
          'toolNames',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        keyResults: $checkedConvert(
          'keyResults',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        planState: $checkedConvert('planState', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CompactionSummaryToJson(CompactionSummary instance) =>
    <String, dynamic>{
      'decisions': instance.decisions,
      'toolNames': instance.toolNames,
      'keyResults': instance.keyResults,
      'planState': ?instance.planState,
    };
