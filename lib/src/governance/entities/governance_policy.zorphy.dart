// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'governance_policy.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class GovernancePolicy {
  GovernancePolicy({
    required String this.id,
    required List<String> this.toolAllowList,
    required List<String> this.toolDenyList,
    required Map<String, RiskTier> this.riskTiers,
    required List<RedactionRule> this.redactionRules,
    required List<RiskTier> this.requireApprovalForTiers,
    int? this.oversizedResultThreshold,
  });

  factory GovernancePolicy.fromJson(Map<String, dynamic> json) =>
      _$GovernancePolicyFromJson(json);

  final String id;

  final List<String> toolAllowList;

  final List<String> toolDenyList;

  final Map<String, RiskTier> riskTiers;

  final List<RedactionRule> redactionRules;

  final List<RiskTier> requireApprovalForTiers;

  final int? oversizedResultThreshold;

  GovernancePolicy copyWith({
    String? id,
    List<String>? toolAllowList,
    List<String>? toolDenyList,
    Map<String, RiskTier>? riskTiers,
    List<RedactionRule>? redactionRules,
    List<RiskTier>? requireApprovalForTiers,
    int? oversizedResultThreshold,
  }) {
    return GovernancePolicy(
      id: id ?? this.id,
      toolAllowList: toolAllowList ?? this.toolAllowList,
      toolDenyList: toolDenyList ?? this.toolDenyList,
      riskTiers: riskTiers ?? this.riskTiers,
      redactionRules: redactionRules ?? this.redactionRules,
      requireApprovalForTiers:
          requireApprovalForTiers ?? this.requireApprovalForTiers,
      oversizedResultThreshold:
          oversizedResultThreshold ?? this.oversizedResultThreshold,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  GovernancePolicy copyWithField<T>(Field<GovernancePolicy, T> field, T value) {
    switch (field.name) {
      case 'id':
        return copyWith(id: value as String);
      case 'toolAllowList':
        return copyWith(toolAllowList: value as List<String>);
      case 'toolDenyList':
        return copyWith(toolDenyList: value as List<String>);
      case 'riskTiers':
        return copyWith(riskTiers: value as Map<String, RiskTier>);
      case 'redactionRules':
        return copyWith(redactionRules: value as List<RedactionRule>);
      case 'requireApprovalForTiers':
        return copyWith(requireApprovalForTiers: value as List<RiskTier>);
      case 'oversizedResultThreshold':
        return copyWith(oversizedResultThreshold: value as int?);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'GovernancePolicy has no settable field with this name',
        );
    }
  }

  GovernancePolicy copyWithGovernancePolicy({
    String? id,
    List<String>? toolAllowList,
    List<String>? toolDenyList,
    Map<String, RiskTier>? riskTiers,
    List<RedactionRule>? redactionRules,
    List<RiskTier>? requireApprovalForTiers,
    int? oversizedResultThreshold,
  }) {
    return copyWith(
      id: id,
      toolAllowList: toolAllowList,
      toolDenyList: toolDenyList,
      riskTiers: riskTiers,
      redactionRules: redactionRules,
      requireApprovalForTiers: requireApprovalForTiers,
      oversizedResultThreshold: oversizedResultThreshold,
    );
  }

  GovernancePolicy patchWithGovernancePolicy([
    GovernancePolicyPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? GovernancePolicyPatch();
    final _patchMap = _patcher.patchMap;
    return GovernancePolicy(
      id: _patchMap.containsKey(GovernancePolicy$.id)
          ? ((_patchMap[GovernancePolicy$.id] is Function)
                    ? _patchMap[GovernancePolicy$.id](this.id)
                    : (_patchMap[GovernancePolicy$.id] is Patch)
                    ? _patchMap[GovernancePolicy$.id].applyTo(this.id)
                    : _patchMap[GovernancePolicy$.id])
                as String
          : this.id,
      toolAllowList: _patchMap.containsKey(GovernancePolicy$.toolAllowList)
          ? ((_patchMap[GovernancePolicy$.toolAllowList] is Function)
                    ? _patchMap[GovernancePolicy$.toolAllowList](
                        this.toolAllowList,
                      )
                    : (_patchMap[GovernancePolicy$.toolAllowList] is Patch)
                    ? _patchMap[GovernancePolicy$.toolAllowList].applyTo(
                        this.toolAllowList,
                      )
                    : _patchMap[GovernancePolicy$.toolAllowList])
                as List<String>
          : this.toolAllowList,
      toolDenyList: _patchMap.containsKey(GovernancePolicy$.toolDenyList)
          ? ((_patchMap[GovernancePolicy$.toolDenyList] is Function)
                    ? _patchMap[GovernancePolicy$.toolDenyList](
                        this.toolDenyList,
                      )
                    : (_patchMap[GovernancePolicy$.toolDenyList] is Patch)
                    ? _patchMap[GovernancePolicy$.toolDenyList].applyTo(
                        this.toolDenyList,
                      )
                    : _patchMap[GovernancePolicy$.toolDenyList])
                as List<String>
          : this.toolDenyList,
      riskTiers: _patchMap.containsKey(GovernancePolicy$.riskTiers)
          ? ((_patchMap[GovernancePolicy$.riskTiers] is Function)
                    ? _patchMap[GovernancePolicy$.riskTiers](this.riskTiers)
                    : (_patchMap[GovernancePolicy$.riskTiers] is Patch)
                    ? _patchMap[GovernancePolicy$.riskTiers].applyTo(
                        this.riskTiers,
                      )
                    : _patchMap[GovernancePolicy$.riskTiers])
                as Map<String, RiskTier>
          : this.riskTiers,
      redactionRules: _patchMap.containsKey(GovernancePolicy$.redactionRules)
          ? ((_patchMap[GovernancePolicy$.redactionRules] is Function)
                    ? _patchMap[GovernancePolicy$.redactionRules](
                        this.redactionRules,
                      )
                    : (_patchMap[GovernancePolicy$.redactionRules] is Patch)
                    ? _patchMap[GovernancePolicy$.redactionRules].applyTo(
                        this.redactionRules,
                      )
                    : _patchMap[GovernancePolicy$.redactionRules])
                as List<RedactionRule>
          : this.redactionRules,
      requireApprovalForTiers:
          _patchMap.containsKey(GovernancePolicy$.requireApprovalForTiers)
          ? ((_patchMap[GovernancePolicy$.requireApprovalForTiers] is Function)
                    ? _patchMap[GovernancePolicy$.requireApprovalForTiers](
                        this.requireApprovalForTiers,
                      )
                    : (_patchMap[GovernancePolicy$.requireApprovalForTiers]
                          is Patch)
                    ? _patchMap[GovernancePolicy$.requireApprovalForTiers]
                          .applyTo(this.requireApprovalForTiers)
                    : _patchMap[GovernancePolicy$.requireApprovalForTiers])
                as List<RiskTier>
          : this.requireApprovalForTiers,
      oversizedResultThreshold:
          _patchMap.containsKey(GovernancePolicy$.oversizedResultThreshold)
          ? ((_patchMap[GovernancePolicy$.oversizedResultThreshold] is Function)
                    ? _patchMap[GovernancePolicy$.oversizedResultThreshold](
                        this.oversizedResultThreshold,
                      )
                    : (_patchMap[GovernancePolicy$.oversizedResultThreshold]
                          is Patch)
                    ? _patchMap[GovernancePolicy$.oversizedResultThreshold]
                          .applyTo(this.oversizedResultThreshold)
                    : _patchMap[GovernancePolicy$.oversizedResultThreshold])
                as int?
          : this.oversizedResultThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GovernancePolicy &&
        id == other.id &&
        toolAllowList == other.toolAllowList &&
        toolDenyList == other.toolDenyList &&
        riskTiers == other.riskTiers &&
        redactionRules == other.redactionRules &&
        requireApprovalForTiers == other.requireApprovalForTiers &&
        oversizedResultThreshold == other.oversizedResultThreshold;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.toolAllowList,
      this.toolDenyList,
      this.riskTiers,
      this.redactionRules,
      this.requireApprovalForTiers,
      this.oversizedResultThreshold,
    );
  }

  @override
  String toString() {
    return 'GovernancePolicy(' +
        'id: ${id}' +
        ', ' +
        'toolAllowList: ${toolAllowList}' +
        ', ' +
        'toolDenyList: ${toolDenyList}' +
        ', ' +
        'riskTiers: ${riskTiers}' +
        ', ' +
        'redactionRules: ${redactionRules}' +
        ', ' +
        'requireApprovalForTiers: ${requireApprovalForTiers}' +
        ', ' +
        'oversizedResultThreshold: ${oversizedResultThreshold})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$GovernancePolicyToJson(this);
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

extension GovernancePolicyPropertyHelpers on GovernancePolicy {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasToolAllowList {
    return this.toolAllowList.isNotEmpty;
  }

  bool get noToolAllowList {
    return this.toolAllowList.isEmpty;
  }

  bool get hasToolDenyList {
    return this.toolDenyList.isNotEmpty;
  }

  bool get noToolDenyList {
    return this.toolDenyList.isEmpty;
  }

  bool get hasRiskTiers {
    return this.riskTiers.isNotEmpty;
  }

  bool get noRiskTiers {
    return this.riskTiers.isEmpty;
  }

  bool get hasRedactionRules {
    return this.redactionRules.isNotEmpty;
  }

  bool get noRedactionRules {
    return this.redactionRules.isEmpty;
  }

  bool get hasRequireApprovalForTiers {
    return this.requireApprovalForTiers.isNotEmpty;
  }

  bool get noRequireApprovalForTiers {
    return this.requireApprovalForTiers.isEmpty;
  }

  bool get hasOversizedResultThreshold {
    return this.oversizedResultThreshold != null;
  }

  bool get noOversizedResultThreshold {
    return this.oversizedResultThreshold == null;
  }

  int get oversizedResultThresholdRequired {
    return this.oversizedResultThreshold ??
        (throw StateError('oversizedResultThreshold is required but was null'));
  }
}

extension GovernancePolicySerialization on GovernancePolicy {
  Map<String, dynamic> toJson() {
    return _$GovernancePolicyToJson(this);
  }
}

enum GovernancePolicy$ {
  id,
  toolAllowList,
  toolDenyList,
  riskTiers,
  redactionRules,
  requireApprovalForTiers,
  oversizedResultThreshold,
}

class GovernancePolicyPatch
    extends PatchBase<GovernancePolicy, GovernancePolicy$> {
  GovernancePolicy applyTo(GovernancePolicy entity) {
    return entity.patchWithGovernancePolicy(this);
  }

  GovernancePolicyPatch withId(String? value) {
    patchMap[GovernancePolicy$.id] = value;
    return this;
  }

  GovernancePolicyPatch withToolAllowList(List<String>? value) {
    patchMap[GovernancePolicy$.toolAllowList] = value;
    return this;
  }

  GovernancePolicyPatch withToolDenyList(List<String>? value) {
    patchMap[GovernancePolicy$.toolDenyList] = value;
    return this;
  }

  GovernancePolicyPatch withRiskTiers(Map<String, RiskTier>? value) {
    patchMap[GovernancePolicy$.riskTiers] = value;
    return this;
  }

  GovernancePolicyPatch withRedactionRules(List<RedactionRule>? value) {
    patchMap[GovernancePolicy$.redactionRules] = value;
    return this;
  }

  GovernancePolicyPatch updateRedactionRulesAt(
    int index,
    RedactionRulePatch Function(RedactionRulePatch) patch,
  ) {
    patchMap[GovernancePolicy$.redactionRules] = (List<dynamic> list) {
      var updatedList = List<RedactionRule>.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          RedactionRulePatch(),
        ).applyTo(updatedList[index]);
      }
      return updatedList;
    };
    return this;
  }

  GovernancePolicyPatch withRequireApprovalForTiers(List<RiskTier>? value) {
    patchMap[GovernancePolicy$.requireApprovalForTiers] = value;
    return this;
  }

  GovernancePolicyPatch withOversizedResultThreshold(int? value) {
    patchMap[GovernancePolicy$.oversizedResultThreshold] = value;
    return this;
  }
}

/// Field descriptors for [GovernancePolicy] query construction
abstract final class GovernancePolicyFields {
  static const id = Field<GovernancePolicy, String>('id', _$id);

  static const toolAllowList = Field<GovernancePolicy, List<String>>(
    'toolAllowList',
    _$toolAllowList,
  );

  static const toolDenyList = Field<GovernancePolicy, List<String>>(
    'toolDenyList',
    _$toolDenyList,
  );

  static const riskTiers = Field<GovernancePolicy, Map<String, RiskTier>>(
    'riskTiers',
    _$riskTiers,
  );

  static const redactionRules = Field<GovernancePolicy, List<RedactionRule>>(
    'redactionRules',
    _$redactionRules,
  );

  static const requireApprovalForTiers =
      Field<GovernancePolicy, List<RiskTier>>(
        'requireApprovalForTiers',
        _$requireApprovalForTiers,
      );

  static const oversizedResultThreshold = Field<GovernancePolicy, int?>(
    'oversizedResultThreshold',
    _$oversizedResultThreshold,
  );

  static String _$id(GovernancePolicy e) {
    return e.id;
  }

  static List<String> _$toolAllowList(GovernancePolicy e) {
    return e.toolAllowList;
  }

  static List<String> _$toolDenyList(GovernancePolicy e) {
    return e.toolDenyList;
  }

  static Map<String, RiskTier> _$riskTiers(GovernancePolicy e) {
    return e.riskTiers;
  }

  static List<RedactionRule> _$redactionRules(GovernancePolicy e) {
    return e.redactionRules;
  }

  static List<RiskTier> _$requireApprovalForTiers(GovernancePolicy e) {
    return e.requireApprovalForTiers;
  }

  static int? _$oversizedResultThreshold(GovernancePolicy e) {
    return e.oversizedResultThreshold;
  }
}

extension GovernancePolicyCompareE on GovernancePolicy {
  Map<String, dynamic> compareToGovernancePolicy(GovernancePolicy other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (toolAllowList != other.toolAllowList) {
      diff['toolAllowList'] = () => other.toolAllowList;
    }

    if (toolDenyList != other.toolDenyList) {
      diff['toolDenyList'] = () => other.toolDenyList;
    }

    if (riskTiers != other.riskTiers) {
      diff['riskTiers'] = () => other.riskTiers;
    }

    if (redactionRules != other.redactionRules) {
      diff['redactionRules'] = () => other.redactionRules;
    }

    if (requireApprovalForTiers != other.requireApprovalForTiers) {
      diff['requireApprovalForTiers'] = () => other.requireApprovalForTiers;
    }

    if (oversizedResultThreshold != other.oversizedResultThreshold) {
      diff['oversizedResultThreshold'] = () => other.oversizedResultThreshold;
    }
    return diff;
  }
}
