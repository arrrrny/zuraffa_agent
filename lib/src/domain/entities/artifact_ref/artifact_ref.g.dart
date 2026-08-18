// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactRef _$ArtifactRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactRef', json, ($checkedConvert) {
      final val = ArtifactRef(
        kind: $checkedConvert('kind', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String),
        uri: $checkedConvert('uri', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactRefToJson(ArtifactRef instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'id': instance.id,
      'uri': ?instance.uri,
    };
