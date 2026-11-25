// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redaction_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedactionRule _$RedactionRuleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RedactionRule', json, ($checkedConvert) {
      final val = RedactionRule(
        name: $checkedConvert('name', (v) => v as String),
        pattern: $checkedConvert('pattern', (v) => v as String),
        replacement: $checkedConvert('replacement', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RedactionRuleToJson(RedactionRule instance) =>
    <String, dynamic>{
      'name': instance.name,
      'pattern': instance.pattern,
      'replacement': instance.replacement,
    };
