// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'enums.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Enums {
  Enums({
    required String this.id,
    required List<String> this.values,
    String? this.description,
  });

  factory Enums.fromJson(Map<String, dynamic> json) => _$EnumsFromJson(json);

  final String id;

  final List<String> values;

  final String? description;

  Enums copyWith({String? id, List<String>? values, String? description}) {
    return Enums(
      id: id ?? this.id,
      values: values ?? this.values,
      description: description ?? this.description,
    );
  }

  Enums copyWithEnums({String? id, List<String>? values, String? description}) {
    return copyWith(id: id, values: values, description: description);
  }

  Enums patchWithEnums([EnumsPatch? patchInput]) {
    final _patcher = patchInput ?? EnumsPatch();
    final _patchMap = _patcher.patchMap;
    return Enums(
      id: _patchMap.containsKey(Enums$.id)
          ? ((_patchMap[Enums$.id] is Function)
                    ? _patchMap[Enums$.id](this.id)
                    : (_patchMap[Enums$.id] is Patch)
                    ? _patchMap[Enums$.id].applyTo(this.id)
                    : _patchMap[Enums$.id])
                as String
          : this.id,
      values: _patchMap.containsKey(Enums$.values_)
          ? ((_patchMap[Enums$.values_] is Function)
                    ? _patchMap[Enums$.values_](this.values)
                    : (_patchMap[Enums$.values_] is Patch)
                    ? _patchMap[Enums$.values_].applyTo(this.values)
                    : _patchMap[Enums$.values_])
                as List<String>
          : this.values,
      description: _patchMap.containsKey(Enums$.description)
          ? ((_patchMap[Enums$.description] is Function)
                    ? _patchMap[Enums$.description](this.description)
                    : (_patchMap[Enums$.description] is Patch)
                    ? _patchMap[Enums$.description].applyTo(this.description)
                    : _patchMap[Enums$.description])
                as String?
          : this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enums &&
        id == other.id &&
        values == other.values &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.values, this.description);
  }

  @override
  String toString() {
    return 'Enums(' +
        'id: ${id}' +
        ', ' +
        'values: ${values}' +
        ', ' +
        'description: ${description})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$EnumsToJson(this);
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

extension EnumsPropertyHelpers on Enums {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasValues {
    return this.values.isNotEmpty;
  }

  bool get noValues {
    return this.values.isEmpty;
  }

  bool get hasDescription {
    return this.description?.isNotEmpty == true;
  }

  bool get noDescription {
    return this.description?.isEmpty ?? true;
  }

  String get descriptionRequired {
    return this.description ??
        (throw StateError('description is required but was null'));
  }
}

extension EnumsSerialization on Enums {
  Map<String, dynamic> toJson() {
    return _$EnumsToJson(this);
  }
}

enum Enums$ { id, values_, description }

class EnumsPatch extends PatchBase<Enums, Enums$> {
  Enums applyTo(Enums entity) {
    return entity.patchWithEnums(this);
  }

  EnumsPatch withId(String? value) {
    patchMap[Enums$.id] = value;
    return this;
  }

  EnumsPatch withValues(List<String>? value) {
    patchMap[Enums$.values_] = value;
    return this;
  }

  EnumsPatch withDescription(String? value) {
    patchMap[Enums$.description] = value;
    return this;
  }
}

/// Field descriptors for [Enums] query construction
abstract final class EnumsFields {
  static const id = Field<Enums, String>('id', _$id);

  static const values = Field<Enums, List<String>>('values', _$values);

  static const description = Field<Enums, String?>(
    'description',
    _$description,
  );

  static String _$id(Enums e) {
    return e.id;
  }

  static List<String> _$values(Enums e) {
    return e.values;
  }

  static String? _$description(Enums e) {
    return e.description;
  }
}

extension EnumsCompareE on Enums {
  Map<String, dynamic> compareToEnums(Enums other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (values != other.values) {
      diff['values'] = () => other.values;
    }

    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    return diff;
  }
}
