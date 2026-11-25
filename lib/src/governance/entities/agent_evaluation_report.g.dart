// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_evaluation_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentEvaluationReport _$AgentEvaluationReportFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentEvaluationReport', json, ($checkedConvert) {
  final val = AgentEvaluationReport(
    id: $checkedConvert('id', (v) => v as String),
    at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
    suite: $checkedConvert('suite', (v) => v as String),
    caseName: $checkedConvert('caseName', (v) => v as String),
    outcome: $checkedConvert('outcome', (v) => v as String),
    redactedTranscript: $checkedConvert(
      'redactedTranscript',
      (v) => v as String?,
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentEvaluationReportToJson(
  AgentEvaluationReport instance,
) => <String, dynamic>{
  'id': instance.id,
  'at': instance.at.toIso8601String(),
  'suite': instance.suite,
  'caseName': instance.caseName,
  'outcome': instance.outcome,
  'redactedTranscript': ?instance.redactedTranscript,
};
