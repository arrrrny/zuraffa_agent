// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'sub_agent_type.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class SubAgentType {
  SubAgentType({
    required String this.id,
    required String this.name,
    required String this.specRef,
    required List<String> this.allowlist,
    required String this.budgetProfile,
  });

  factory SubAgentType.fromJson(Map<String, dynamic> json) =>
      _$SubAgentTypeFromJson(json);

  final String id;

  final String name;

  final String specRef;

  final List<String> allowlist;

  final String budgetProfile;

  SubAgentType copyWith({
    String? id,
    String? name,
    String? specRef,
    List<String>? allowlist,
    String? budgetProfile,
  }) {
    return SubAgentType(
      id: id ?? this.id,
      name: name ?? this.name,
      specRef: specRef ?? this.specRef,
      allowlist: allowlist ?? this.allowlist,
      budgetProfile: budgetProfile ?? this.budgetProfile,
    );
  }

  SubAgentType copyWithSubAgentType({
    String? id,
    String? name,
    String? specRef,
    List<String>? allowlist,
    String? budgetProfile,
  }) {
    return copyWith(
      id: id,
      name: name,
      specRef: specRef,
      allowlist: allowlist,
      budgetProfile: budgetProfile,
    );
  }

  SubAgentType patchWithSubAgentType([SubAgentTypePatch? patchInput]) {
    final _patcher = patchInput ?? SubAgentTypePatch();
    final _patchMap = _patcher.patchMap;
    return SubAgentType(
      id: _patchMap.containsKey(SubAgentType$.id)
          ? ((_patchMap[SubAgentType$.id] is Function)
                    ? _patchMap[SubAgentType$.id](this.id)
                    : (_patchMap[SubAgentType$.id] is Patch)
                    ? _patchMap[SubAgentType$.id].applyTo(this.id)
                    : _patchMap[SubAgentType$.id])
                as String
          : this.id,
      name: _patchMap.containsKey(SubAgentType$.name_)
          ? ((_patchMap[SubAgentType$.name_] is Function)
                    ? _patchMap[SubAgentType$.name_](this.name)
                    : (_patchMap[SubAgentType$.name_] is Patch)
                    ? _patchMap[SubAgentType$.name_].applyTo(this.name)
                    : _patchMap[SubAgentType$.name_])
                as String
          : this.name,
      specRef: _patchMap.containsKey(SubAgentType$.specRef)
          ? ((_patchMap[SubAgentType$.specRef] is Function)
                    ? _patchMap[SubAgentType$.specRef](this.specRef)
                    : (_patchMap[SubAgentType$.specRef] is Patch)
                    ? _patchMap[SubAgentType$.specRef].applyTo(this.specRef)
                    : _patchMap[SubAgentType$.specRef])
                as String
          : this.specRef,
      allowlist: _patchMap.containsKey(SubAgentType$.allowlist)
          ? ((_patchMap[SubAgentType$.allowlist] is Function)
                    ? _patchMap[SubAgentType$.allowlist](this.allowlist)
                    : (_patchMap[SubAgentType$.allowlist] is Patch)
                    ? _patchMap[SubAgentType$.allowlist].applyTo(this.allowlist)
                    : _patchMap[SubAgentType$.allowlist])
                as List<String>
          : this.allowlist,
      budgetProfile: _patchMap.containsKey(SubAgentType$.budgetProfile)
          ? ((_patchMap[SubAgentType$.budgetProfile] is Function)
                    ? _patchMap[SubAgentType$.budgetProfile](this.budgetProfile)
                    : (_patchMap[SubAgentType$.budgetProfile] is Patch)
                    ? _patchMap[SubAgentType$.budgetProfile].applyTo(
                        this.budgetProfile,
                      )
                    : _patchMap[SubAgentType$.budgetProfile])
                as String
          : this.budgetProfile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubAgentType &&
        id == other.id &&
        name == other.name &&
        specRef == other.specRef &&
        allowlist == other.allowlist &&
        budgetProfile == other.budgetProfile;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.name,
      this.specRef,
      this.allowlist,
      this.budgetProfile,
    );
  }

  @override
  String toString() {
    return 'SubAgentType(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'specRef: ${specRef}' +
        ', ' +
        'allowlist: ${allowlist}' +
        ', ' +
        'budgetProfile: ${budgetProfile})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SubAgentTypeToJson(this);
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

extension SubAgentTypePropertyHelpers on SubAgentType {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasName {
    return this.name.isNotEmpty;
  }

  bool get noName {
    return this.name.isEmpty;
  }

  bool get hasSpecRef {
    return this.specRef.isNotEmpty;
  }

  bool get noSpecRef {
    return this.specRef.isEmpty;
  }

  bool get hasAllowlist {
    return this.allowlist.isNotEmpty;
  }

  bool get noAllowlist {
    return this.allowlist.isEmpty;
  }

  bool get hasBudgetProfile {
    return this.budgetProfile.isNotEmpty;
  }

  bool get noBudgetProfile {
    return this.budgetProfile.isEmpty;
  }
}

extension SubAgentTypeSerialization on SubAgentType {
  Map<String, dynamic> toJson() {
    return _$SubAgentTypeToJson(this);
  }
}

enum SubAgentType$ { id, name_, specRef, allowlist, budgetProfile }

class SubAgentTypePatch extends PatchBase<SubAgentType, SubAgentType$> {
  SubAgentType applyTo(SubAgentType entity) {
    return entity.patchWithSubAgentType(this);
  }

  SubAgentTypePatch withId(String? value) {
    patchMap[SubAgentType$.id] = value;
    return this;
  }

  SubAgentTypePatch withName(String? value) {
    patchMap[SubAgentType$.name_] = value;
    return this;
  }

  SubAgentTypePatch withSpecRef(String? value) {
    patchMap[SubAgentType$.specRef] = value;
    return this;
  }

  SubAgentTypePatch withAllowlist(List<String>? value) {
    patchMap[SubAgentType$.allowlist] = value;
    return this;
  }

  SubAgentTypePatch withBudgetProfile(String? value) {
    patchMap[SubAgentType$.budgetProfile] = value;
    return this;
  }
}

/// Field descriptors for [SubAgentType] query construction
abstract final class SubAgentTypeFields {
  static const id = Field<SubAgentType, String>('id', _$id);

  static const name = Field<SubAgentType, String>('name', _$name);

  static const specRef = Field<SubAgentType, String>('specRef', _$specRef);

  static const allowlist = Field<SubAgentType, List<String>>(
    'allowlist',
    _$allowlist,
  );

  static const budgetProfile = Field<SubAgentType, String>(
    'budgetProfile',
    _$budgetProfile,
  );

  static String _$id(SubAgentType e) {
    return e.id;
  }

  static String _$name(SubAgentType e) {
    return e.name;
  }

  static String _$specRef(SubAgentType e) {
    return e.specRef;
  }

  static List<String> _$allowlist(SubAgentType e) {
    return e.allowlist;
  }

  static String _$budgetProfile(SubAgentType e) {
    return e.budgetProfile;
  }
}

extension SubAgentTypeCompareE on SubAgentType {
  Map<String, dynamic> compareToSubAgentType(SubAgentType other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (name != other.name) {
      diff['name'] = () => other.name;
    }

    if (specRef != other.specRef) {
      diff['specRef'] = () => other.specRef;
    }

    if (allowlist != other.allowlist) {
      diff['allowlist'] = () => other.allowlist;
    }

    if (budgetProfile != other.budgetProfile) {
      diff['budgetProfile'] = () => other.budgetProfile;
    }
    return diff;
  }
}
