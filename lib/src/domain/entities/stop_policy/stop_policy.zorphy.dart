// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'stop_policy.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class StopPolicy {
  StopPolicy({
    String? id,
    required int this.maxTurns,
    required int this.wallClockTimeoutMs,
    required int this.repetitionThreshold,
    required bool this.enabled,
  }) : this.id = id ?? const Uuid().v4();

  factory StopPolicy.fromJson(Map<String, dynamic> json) =>
      _$StopPolicyFromJson(json);

  final String id;

  final int maxTurns;

  final int wallClockTimeoutMs;

  final int repetitionThreshold;

  final bool enabled;

  StopPolicy copyWith({
    String? id,
    int? maxTurns,
    int? wallClockTimeoutMs,
    int? repetitionThreshold,
    bool? enabled,
  }) {
    return StopPolicy(
      id: id ?? this.id,
      maxTurns: maxTurns ?? this.maxTurns,
      wallClockTimeoutMs: wallClockTimeoutMs ?? this.wallClockTimeoutMs,
      repetitionThreshold: repetitionThreshold ?? this.repetitionThreshold,
      enabled: enabled ?? this.enabled,
    );
  }

  StopPolicy copyWithStopPolicy({
    String? id,
    int? maxTurns,
    int? wallClockTimeoutMs,
    int? repetitionThreshold,
    bool? enabled,
  }) {
    return copyWith(
      id: id,
      maxTurns: maxTurns,
      wallClockTimeoutMs: wallClockTimeoutMs,
      repetitionThreshold: repetitionThreshold,
      enabled: enabled,
    );
  }

  StopPolicy patchWithStopPolicy([StopPolicyPatch? patchInput]) {
    final _patcher = patchInput ?? StopPolicyPatch();
    final _patchMap = _patcher.patchMap;
    return StopPolicy(
      id: _patchMap.containsKey(StopPolicy$.id)
          ? ((_patchMap[StopPolicy$.id] is Function)
                    ? _patchMap[StopPolicy$.id](this.id)
                    : (_patchMap[StopPolicy$.id] is Patch)
                    ? _patchMap[StopPolicy$.id].applyTo(this.id)
                    : _patchMap[StopPolicy$.id])
                as String
          : this.id,
      maxTurns: _patchMap.containsKey(StopPolicy$.maxTurns)
          ? ((_patchMap[StopPolicy$.maxTurns] is Function)
                    ? _patchMap[StopPolicy$.maxTurns](this.maxTurns)
                    : (_patchMap[StopPolicy$.maxTurns] is Patch)
                    ? _patchMap[StopPolicy$.maxTurns].applyTo(this.maxTurns)
                    : _patchMap[StopPolicy$.maxTurns])
                as int
          : this.maxTurns,
      wallClockTimeoutMs: _patchMap.containsKey(StopPolicy$.wallClockTimeoutMs)
          ? ((_patchMap[StopPolicy$.wallClockTimeoutMs] is Function)
                    ? _patchMap[StopPolicy$.wallClockTimeoutMs](
                        this.wallClockTimeoutMs,
                      )
                    : (_patchMap[StopPolicy$.wallClockTimeoutMs] is Patch)
                    ? _patchMap[StopPolicy$.wallClockTimeoutMs].applyTo(
                        this.wallClockTimeoutMs,
                      )
                    : _patchMap[StopPolicy$.wallClockTimeoutMs])
                as int
          : this.wallClockTimeoutMs,
      repetitionThreshold:
          _patchMap.containsKey(StopPolicy$.repetitionThreshold)
          ? ((_patchMap[StopPolicy$.repetitionThreshold] is Function)
                    ? _patchMap[StopPolicy$.repetitionThreshold](
                        this.repetitionThreshold,
                      )
                    : (_patchMap[StopPolicy$.repetitionThreshold] is Patch)
                    ? _patchMap[StopPolicy$.repetitionThreshold].applyTo(
                        this.repetitionThreshold,
                      )
                    : _patchMap[StopPolicy$.repetitionThreshold])
                as int
          : this.repetitionThreshold,
      enabled: _patchMap.containsKey(StopPolicy$.enabled)
          ? ((_patchMap[StopPolicy$.enabled] is Function)
                    ? _patchMap[StopPolicy$.enabled](this.enabled)
                    : (_patchMap[StopPolicy$.enabled] is Patch)
                    ? _patchMap[StopPolicy$.enabled].applyTo(this.enabled)
                    : _patchMap[StopPolicy$.enabled])
                as bool
          : this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StopPolicy &&
        id == other.id &&
        maxTurns == other.maxTurns &&
        wallClockTimeoutMs == other.wallClockTimeoutMs &&
        repetitionThreshold == other.repetitionThreshold &&
        enabled == other.enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.maxTurns,
      this.wallClockTimeoutMs,
      this.repetitionThreshold,
      this.enabled,
    );
  }

  @override
  String toString() {
    return 'StopPolicy(' +
        'id: ${id}' +
        ', ' +
        'maxTurns: ${maxTurns}' +
        ', ' +
        'wallClockTimeoutMs: ${wallClockTimeoutMs}' +
        ', ' +
        'repetitionThreshold: ${repetitionThreshold}' +
        ', ' +
        'enabled: ${enabled})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$StopPolicyToJson(this);
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

extension StopPolicyPropertyHelpers on StopPolicy {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }
}

extension StopPolicySerialization on StopPolicy {
  Map<String, dynamic> toJson() {
    return _$StopPolicyToJson(this);
  }
}

enum StopPolicy$ {
  id,
  maxTurns,
  wallClockTimeoutMs,
  repetitionThreshold,
  enabled,
}

class StopPolicyPatch extends PatchBase<StopPolicy, StopPolicy$> {
  StopPolicy applyTo(StopPolicy entity) {
    return entity.patchWithStopPolicy(this);
  }

  StopPolicyPatch withId(String? value) {
    patchMap[StopPolicy$.id] = value;
    return this;
  }

  StopPolicyPatch withMaxTurns(int? value) {
    patchMap[StopPolicy$.maxTurns] = value;
    return this;
  }

  StopPolicyPatch withWallClockTimeoutMs(int? value) {
    patchMap[StopPolicy$.wallClockTimeoutMs] = value;
    return this;
  }

  StopPolicyPatch withRepetitionThreshold(int? value) {
    patchMap[StopPolicy$.repetitionThreshold] = value;
    return this;
  }

  StopPolicyPatch withEnabled(bool? value) {
    patchMap[StopPolicy$.enabled] = value;
    return this;
  }
}

/// Field descriptors for [StopPolicy] query construction
abstract final class StopPolicyFields {
  static const id = Field<StopPolicy, String>('id', _$id);

  static const maxTurns = Field<StopPolicy, int>('maxTurns', _$maxTurns);

  static const wallClockTimeoutMs = Field<StopPolicy, int>(
    'wallClockTimeoutMs',
    _$wallClockTimeoutMs,
  );

  static const repetitionThreshold = Field<StopPolicy, int>(
    'repetitionThreshold',
    _$repetitionThreshold,
  );

  static const enabled = Field<StopPolicy, bool>('enabled', _$enabled);

  static String _$id(StopPolicy e) {
    return e.id;
  }

  static int _$maxTurns(StopPolicy e) {
    return e.maxTurns;
  }

  static int _$wallClockTimeoutMs(StopPolicy e) {
    return e.wallClockTimeoutMs;
  }

  static int _$repetitionThreshold(StopPolicy e) {
    return e.repetitionThreshold;
  }

  static bool _$enabled(StopPolicy e) {
    return e.enabled;
  }
}

extension StopPolicyCompareE on StopPolicy {
  Map<String, dynamic> compareToStopPolicy(StopPolicy other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (maxTurns != other.maxTurns) {
      diff['maxTurns'] = () => other.maxTurns;
    }

    if (wallClockTimeoutMs != other.wallClockTimeoutMs) {
      diff['wallClockTimeoutMs'] = () => other.wallClockTimeoutMs;
    }

    if (repetitionThreshold != other.repetitionThreshold) {
      diff['repetitionThreshold'] = () => other.repetitionThreshold;
    }

    if (enabled != other.enabled) {
      diff['enabled'] = () => other.enabled;
    }
    return diff;
  }
}
