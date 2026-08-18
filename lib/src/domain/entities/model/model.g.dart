// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Model _$ModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Model', json, ($checkedConvert) {
      final val = Model(
        provider: $checkedConvert('provider', (v) => v as String),
        modelId: $checkedConvert('modelId', (v) => v as String),
        contextWindow: $checkedConvert(
          'contextWindow',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
  'provider': instance.provider,
  'modelId': instance.modelId,
  'contextWindow': instance.contextWindow,
};
