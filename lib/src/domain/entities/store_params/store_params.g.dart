// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreParams _$StoreParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreParams', json, ($checkedConvert) {
      final val = StoreParams(
        data: $checkedConvert(
          'data',
          (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$StoreParamsToJson(StoreParams instance) =>
    <String, dynamic>{'data': instance.data, 'mimeType': instance.mimeType};
