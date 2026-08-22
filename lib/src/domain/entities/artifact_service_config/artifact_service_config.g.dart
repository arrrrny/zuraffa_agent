// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_service_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactServiceConfig _$ArtifactServiceConfigFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ArtifactServiceConfig', json, ($checkedConvert) {
  final val = ArtifactServiceConfig(
    thresholdBytes: $checkedConvert(
      'thresholdBytes',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ArtifactServiceConfigToJson(
  ArtifactServiceConfig instance,
) => <String, dynamic>{'thresholdBytes': instance.thresholdBytes};
