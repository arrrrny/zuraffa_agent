// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_summary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchSummaryEntry _$BranchSummaryEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BranchSummaryEntry', json, ($checkedConvert) {
      final val = BranchSummaryEntry(
        id: $checkedConvert('id', (v) => v as String),
        parentId: $checkedConvert('parentId', (v) => v as String?),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        summary: $checkedConvert('summary', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$BranchSummaryEntryToJson(BranchSummaryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'summary': instance.summary,
    };
