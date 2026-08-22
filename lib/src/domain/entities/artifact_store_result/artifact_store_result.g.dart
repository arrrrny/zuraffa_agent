// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_store_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactStoreResult _$ArtifactStoreResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactStoreResult', json, ($checkedConvert) {
      final val = ArtifactStoreResult(
        ref: $checkedConvert(
          'ref',
          (v) => ArtifactRef.fromJson(v as Map<String, dynamic>),
        ),
        summarized: $checkedConvert('summarized', (v) => v as bool),
        summary: $checkedConvert('summary', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactStoreResultToJson(
  ArtifactStoreResult instance,
) => <String, dynamic>{
  'ref': instance.ref.toJson(),
  'summarized': instance.summarized,
  'summary': ?instance.summary,
};
