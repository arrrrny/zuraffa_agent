// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactRef _$ArtifactRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactRef', json, ($checkedConvert) {
      final val = ArtifactRef(
        id: $checkedConvert('id', (v) => v as String),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
        sizeBytes: $checkedConvert('sizeBytes', (v) => (v as num).toInt()),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactRefToJson(ArtifactRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
