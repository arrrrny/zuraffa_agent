// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'redaction_rule.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class RedactionRule {
  RedactionRule({
    required String this.name,
    required String this.pattern,
    required String this.replacement,
  });

  factory RedactionRule.fromJson(Map<String, dynamic> json) =>
      _$RedactionRuleFromJson(json);

  final String name;

  final String pattern;

  final String replacement;

  RedactionRule copyWith({String? name, String? pattern, String? replacement}) {
    return RedactionRule(
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  RedactionRule copyWithField<T>(Field<RedactionRule, T> field, T value) {
    switch (field.name) {
      case 'name':
        return copyWith(name: value as String);
      case 'pattern':
        return copyWith(pattern: value as String);
      case 'replacement':
        return copyWith(replacement: value as String);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'RedactionRule has no settable field with this name',
        );
    }
  }

  RedactionRule copyWithRedactionRule({
    String? name,
    String? pattern,
    String? replacement,
  }) {
    return copyWith(name: name, pattern: pattern, replacement: replacement);
  }

  RedactionRule patchWithRedactionRule([RedactionRulePatch? patchInput]) {
    final _patcher = patchInput ?? RedactionRulePatch();
    final _patchMap = _patcher.patchMap;
    return RedactionRule(
      name: _patchMap.containsKey(RedactionRule$.name_)
          ? ((_patchMap[RedactionRule$.name_] is Function)
                    ? _patchMap[RedactionRule$.name_](this.name)
                    : (_patchMap[RedactionRule$.name_] is Patch)
                    ? _patchMap[RedactionRule$.name_].applyTo(this.name)
                    : _patchMap[RedactionRule$.name_])
                as String
          : this.name,
      pattern: _patchMap.containsKey(RedactionRule$.pattern)
          ? ((_patchMap[RedactionRule$.pattern] is Function)
                    ? _patchMap[RedactionRule$.pattern](this.pattern)
                    : (_patchMap[RedactionRule$.pattern] is Patch)
                    ? _patchMap[RedactionRule$.pattern].applyTo(this.pattern)
                    : _patchMap[RedactionRule$.pattern])
                as String
          : this.pattern,
      replacement: _patchMap.containsKey(RedactionRule$.replacement)
          ? ((_patchMap[RedactionRule$.replacement] is Function)
                    ? _patchMap[RedactionRule$.replacement](this.replacement)
                    : (_patchMap[RedactionRule$.replacement] is Patch)
                    ? _patchMap[RedactionRule$.replacement].applyTo(
                        this.replacement,
                      )
                    : _patchMap[RedactionRule$.replacement])
                as String
          : this.replacement,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedactionRule &&
        name == other.name &&
        pattern == other.pattern &&
        replacement == other.replacement;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.pattern, this.replacement);
  }

  @override
  String toString() {
    return 'RedactionRule(' +
        'name: ${name}' +
        ', ' +
        'pattern: ${pattern}' +
        ', ' +
        'replacement: ${replacement})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RedactionRuleToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension RedactionRulePropertyHelpers on RedactionRule {
  bool get hasName {
    return this.name.isNotEmpty;
  }

  bool get noName {
    return this.name.isEmpty;
  }

  bool get hasPattern {
    return this.pattern.isNotEmpty;
  }

  bool get noPattern {
    return this.pattern.isEmpty;
  }

  bool get hasReplacement {
    return this.replacement.isNotEmpty;
  }

  bool get noReplacement {
    return this.replacement.isEmpty;
  }
}

extension RedactionRuleSerialization on RedactionRule {
  Map<String, dynamic> toJson() {
    return _$RedactionRuleToJson(this);
  }
}

enum RedactionRule$ { name_, pattern, replacement }

class RedactionRulePatch extends PatchBase<RedactionRule, RedactionRule$> {
  RedactionRule applyTo(RedactionRule entity) {
    return entity.patchWithRedactionRule(this);
  }

  RedactionRulePatch withName(String? value) {
    patchMap[RedactionRule$.name_] = value;
    return this;
  }

  RedactionRulePatch withPattern(String? value) {
    patchMap[RedactionRule$.pattern] = value;
    return this;
  }

  RedactionRulePatch withReplacement(String? value) {
    patchMap[RedactionRule$.replacement] = value;
    return this;
  }
}

/// Field descriptors for [RedactionRule] query construction
abstract final class RedactionRuleFields {
  static const name = Field<RedactionRule, String>('name', _$name);

  static const pattern = Field<RedactionRule, String>('pattern', _$pattern);

  static const replacement = Field<RedactionRule, String>(
    'replacement',
    _$replacement,
  );

  static String _$name(RedactionRule e) {
    return e.name;
  }

  static String _$pattern(RedactionRule e) {
    return e.pattern;
  }

  static String _$replacement(RedactionRule e) {
    return e.replacement;
  }
}

extension RedactionRuleCompareE on RedactionRule {
  Map<String, dynamic> compareToRedactionRule(RedactionRule other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }

    if (pattern != other.pattern) {
      diff['pattern'] = () => other.pattern;
    }

    if (replacement != other.replacement) {
      diff['replacement'] = () => other.replacement;
    }
    return diff;
  }
}
