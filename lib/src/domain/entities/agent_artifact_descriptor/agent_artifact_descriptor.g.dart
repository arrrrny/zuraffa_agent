// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_artifact_descriptor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentArtifactDescriptor _$AgentArtifactDescriptorFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentArtifactDescriptor', json, ($checkedConvert) {
  final val = AgentArtifactDescriptor(
    id: $checkedConvert('id', (v) => v as String),
    kind: $checkedConvert('kind', (v) => v as String),
    byteCount: $checkedConvert('byteCount', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentArtifactDescriptorToJson(
  AgentArtifactDescriptor instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'byteCount': instance.byteCount,
};
