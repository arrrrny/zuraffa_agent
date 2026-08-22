// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Artifact _$ArtifactFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Artifact', json, ($checkedConvert) {
      final val = Artifact(
        refId: $checkedConvert('refId', (v) => v as String),
        data: $checkedConvert(
          'data',
          (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactToJson(Artifact instance) => <String, dynamic>{
  'refId': instance.refId,
  'data': instance.data,
};
