// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'future.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Future _$FutureFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Future', json, ($checkedConvert) {
      final val = Future(
        id: $checkedConvert('id', (v) => v as String),
        value: $checkedConvert('value', (v) => v),
      );
      return val;
    });

Map<String, dynamic> _$FutureToJson(Future instance) => <String, dynamic>{
  'id': instance.id,
  'value': ?instance.value,
};
