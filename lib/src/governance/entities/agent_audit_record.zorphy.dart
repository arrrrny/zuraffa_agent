// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_audit_record.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentAuditRecord {
  AgentAuditRecord({
    required String this.id,
    required DateTime this.at,
    required String this.phase,
    required String this.outcome,
    required bool this.redacted,
    required bool this.unredactedOptIn,
    String? this.error,
  });

  factory AgentAuditRecord.fromJson(Map<String, dynamic> json) =>
      _$AgentAuditRecordFromJson(json);

  final String id;

  final DateTime at;

  final String phase;

  final String outcome;

  final bool redacted;

  final bool unredactedOptIn;

  final String? error;

  AgentAuditRecord copyWith({
    String? id,
    DateTime? at,
    String? phase,
    String? outcome,
    bool? redacted,
    bool? unredactedOptIn,
    String? error,
  }) {
    return AgentAuditRecord(
      id: id ?? this.id,
      at: at ?? this.at,
      phase: phase ?? this.phase,
      outcome: outcome ?? this.outcome,
      redacted: redacted ?? this.redacted,
      unredactedOptIn: unredactedOptIn ?? this.unredactedOptIn,
      error: error ?? this.error,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  AgentAuditRecord copyWithField<T>(Field<AgentAuditRecord, T> field, T value) {
    switch (field.name) {
      case 'id':
        return copyWith(id: value as String);
      case 'at':
        return copyWith(at: value as DateTime);
      case 'phase':
        return copyWith(phase: value as String);
      case 'outcome':
        return copyWith(outcome: value as String);
      case 'redacted':
        return copyWith(redacted: value as bool);
      case 'unredactedOptIn':
        return copyWith(unredactedOptIn: value as bool);
      case 'error':
        return copyWith(error: value as String?);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'AgentAuditRecord has no settable field with this name',
        );
    }
  }

  AgentAuditRecord copyWithAgentAuditRecord({
    String? id,
    DateTime? at,
    String? phase,
    String? outcome,
    bool? redacted,
    bool? unredactedOptIn,
    String? error,
  }) {
    return copyWith(
      id: id,
      at: at,
      phase: phase,
      outcome: outcome,
      redacted: redacted,
      unredactedOptIn: unredactedOptIn,
      error: error,
    );
  }

  AgentAuditRecord patchWithAgentAuditRecord([
    AgentAuditRecordPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? AgentAuditRecordPatch();
    final _patchMap = _patcher.patchMap;
    return AgentAuditRecord(
      id: _patchMap.containsKey(AgentAuditRecord$.id)
          ? ((_patchMap[AgentAuditRecord$.id] is Function)
                    ? _patchMap[AgentAuditRecord$.id](this.id)
                    : (_patchMap[AgentAuditRecord$.id] is Patch)
                    ? _patchMap[AgentAuditRecord$.id].applyTo(this.id)
                    : _patchMap[AgentAuditRecord$.id])
                as String
          : this.id,
      at: _patchMap.containsKey(AgentAuditRecord$.at)
          ? ((_patchMap[AgentAuditRecord$.at] is Function)
                    ? _patchMap[AgentAuditRecord$.at](this.at)
                    : (_patchMap[AgentAuditRecord$.at] is Patch)
                    ? _patchMap[AgentAuditRecord$.at].applyTo(this.at)
                    : _patchMap[AgentAuditRecord$.at])
                as DateTime
          : this.at,
      phase: _patchMap.containsKey(AgentAuditRecord$.phase)
          ? ((_patchMap[AgentAuditRecord$.phase] is Function)
                    ? _patchMap[AgentAuditRecord$.phase](this.phase)
                    : (_patchMap[AgentAuditRecord$.phase] is Patch)
                    ? _patchMap[AgentAuditRecord$.phase].applyTo(this.phase)
                    : _patchMap[AgentAuditRecord$.phase])
                as String
          : this.phase,
      outcome: _patchMap.containsKey(AgentAuditRecord$.outcome)
          ? ((_patchMap[AgentAuditRecord$.outcome] is Function)
                    ? _patchMap[AgentAuditRecord$.outcome](this.outcome)
                    : (_patchMap[AgentAuditRecord$.outcome] is Patch)
                    ? _patchMap[AgentAuditRecord$.outcome].applyTo(this.outcome)
                    : _patchMap[AgentAuditRecord$.outcome])
                as String
          : this.outcome,
      redacted: _patchMap.containsKey(AgentAuditRecord$.redacted)
          ? ((_patchMap[AgentAuditRecord$.redacted] is Function)
                    ? _patchMap[AgentAuditRecord$.redacted](this.redacted)
                    : (_patchMap[AgentAuditRecord$.redacted] is Patch)
                    ? _patchMap[AgentAuditRecord$.redacted].applyTo(
                        this.redacted,
                      )
                    : _patchMap[AgentAuditRecord$.redacted])
                as bool
          : this.redacted,
      unredactedOptIn: _patchMap.containsKey(AgentAuditRecord$.unredactedOptIn)
          ? ((_patchMap[AgentAuditRecord$.unredactedOptIn] is Function)
                    ? _patchMap[AgentAuditRecord$.unredactedOptIn](
                        this.unredactedOptIn,
                      )
                    : (_patchMap[AgentAuditRecord$.unredactedOptIn] is Patch)
                    ? _patchMap[AgentAuditRecord$.unredactedOptIn].applyTo(
                        this.unredactedOptIn,
                      )
                    : _patchMap[AgentAuditRecord$.unredactedOptIn])
                as bool
          : this.unredactedOptIn,
      error: _patchMap.containsKey(AgentAuditRecord$.error)
          ? ((_patchMap[AgentAuditRecord$.error] is Function)
                    ? _patchMap[AgentAuditRecord$.error](this.error)
                    : (_patchMap[AgentAuditRecord$.error] is Patch)
                    ? _patchMap[AgentAuditRecord$.error].applyTo(this.error)
                    : _patchMap[AgentAuditRecord$.error])
                as String?
          : this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentAuditRecord &&
        id == other.id &&
        at == other.at &&
        phase == other.phase &&
        outcome == other.outcome &&
        redacted == other.redacted &&
        unredactedOptIn == other.unredactedOptIn &&
        error == other.error;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.at,
      this.phase,
      this.outcome,
      this.redacted,
      this.unredactedOptIn,
      this.error,
    );
  }

  @override
  String toString() {
    return 'AgentAuditRecord(' +
        'id: ${id}' +
        ', ' +
        'at: ${at}' +
        ', ' +
        'phase: ${phase}' +
        ', ' +
        'outcome: ${outcome}' +
        ', ' +
        'redacted: ${redacted}' +
        ', ' +
        'unredactedOptIn: ${unredactedOptIn}' +
        ', ' +
        'error: ${error})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentAuditRecordToJson(this);
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

extension AgentAuditRecordPropertyHelpers on AgentAuditRecord {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasPhase {
    return this.phase.isNotEmpty;
  }

  bool get noPhase {
    return this.phase.isEmpty;
  }

  bool get hasOutcome {
    return this.outcome.isNotEmpty;
  }

  bool get noOutcome {
    return this.outcome.isEmpty;
  }

  bool get hasError {
    return this.error?.isNotEmpty == true;
  }

  bool get noError {
    return this.error?.isEmpty ?? true;
  }

  String get errorRequired {
    return this.error ?? (throw StateError('error is required but was null'));
  }
}

extension AgentAuditRecordSerialization on AgentAuditRecord {
  Map<String, dynamic> toJson() {
    return _$AgentAuditRecordToJson(this);
  }
}

enum AgentAuditRecord$ {
  id,
  at,
  phase,
  outcome,
  redacted,
  unredactedOptIn,
  error,
}

class AgentAuditRecordPatch
    extends PatchBase<AgentAuditRecord, AgentAuditRecord$> {
  AgentAuditRecord applyTo(AgentAuditRecord entity) {
    return entity.patchWithAgentAuditRecord(this);
  }

  AgentAuditRecordPatch withId(String? value) {
    patchMap[AgentAuditRecord$.id] = value;
    return this;
  }

  AgentAuditRecordPatch withAt(DateTime? value) {
    patchMap[AgentAuditRecord$.at] = value;
    return this;
  }

  AgentAuditRecordPatch withPhase(String? value) {
    patchMap[AgentAuditRecord$.phase] = value;
    return this;
  }

  AgentAuditRecordPatch withOutcome(String? value) {
    patchMap[AgentAuditRecord$.outcome] = value;
    return this;
  }

  AgentAuditRecordPatch withRedacted(bool? value) {
    patchMap[AgentAuditRecord$.redacted] = value;
    return this;
  }

  AgentAuditRecordPatch withUnredactedOptIn(bool? value) {
    patchMap[AgentAuditRecord$.unredactedOptIn] = value;
    return this;
  }

  AgentAuditRecordPatch withError(String? value) {
    patchMap[AgentAuditRecord$.error] = value;
    return this;
  }
}

/// Field descriptors for [AgentAuditRecord] query construction
abstract final class AgentAuditRecordFields {
  static const id = Field<AgentAuditRecord, String>('id', _$id);

  static const at = Field<AgentAuditRecord, DateTime>('at', _$at);

  static const phase = Field<AgentAuditRecord, String>('phase', _$phase);

  static const outcome = Field<AgentAuditRecord, String>('outcome', _$outcome);

  static const redacted = Field<AgentAuditRecord, bool>('redacted', _$redacted);

  static const unredactedOptIn = Field<AgentAuditRecord, bool>(
    'unredactedOptIn',
    _$unredactedOptIn,
  );

  static const error = Field<AgentAuditRecord, String?>('error', _$error);

  static String _$id(AgentAuditRecord e) {
    return e.id;
  }

  static DateTime _$at(AgentAuditRecord e) {
    return e.at;
  }

  static String _$phase(AgentAuditRecord e) {
    return e.phase;
  }

  static String _$outcome(AgentAuditRecord e) {
    return e.outcome;
  }

  static bool _$redacted(AgentAuditRecord e) {
    return e.redacted;
  }

  static bool _$unredactedOptIn(AgentAuditRecord e) {
    return e.unredactedOptIn;
  }

  static String? _$error(AgentAuditRecord e) {
    return e.error;
  }
}

extension AgentAuditRecordCompareE on AgentAuditRecord {
  Map<String, dynamic> compareToAgentAuditRecord(AgentAuditRecord other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (at != other.at) {
      diff['at'] = () => other.at;
    }

    if (phase != other.phase) {
      diff['phase'] = () => other.phase;
    }

    if (outcome != other.outcome) {
      diff['outcome'] = () => other.outcome;
    }

    if (redacted != other.redacted) {
      diff['redacted'] = () => other.redacted;
    }

    if (unredactedOptIn != other.unredactedOptIn) {
      diff['unredactedOptIn'] = () => other.unredactedOptIn;
    }

    if (error != other.error) {
      diff['error'] = () => other.error;
    }
    return diff;
  }
}
