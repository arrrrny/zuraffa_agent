// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_evaluation_report.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentEvaluationReport {
  AgentEvaluationReport({
    required String this.id,
    required DateTime this.at,
    required String this.suite,
    required String this.caseName,
    required String this.outcome,
    String? this.redactedTranscript,
  });

  factory AgentEvaluationReport.fromJson(Map<String, dynamic> json) =>
      _$AgentEvaluationReportFromJson(json);

  final String id;

  final DateTime at;

  final String suite;

  final String caseName;

  final String outcome;

  final String? redactedTranscript;

  AgentEvaluationReport copyWith({
    String? id,
    DateTime? at,
    String? suite,
    String? caseName,
    String? outcome,
    String? redactedTranscript,
  }) {
    return AgentEvaluationReport(
      id: id ?? this.id,
      at: at ?? this.at,
      suite: suite ?? this.suite,
      caseName: caseName ?? this.caseName,
      outcome: outcome ?? this.outcome,
      redactedTranscript: redactedTranscript ?? this.redactedTranscript,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  AgentEvaluationReport copyWithField<T>(
    Field<AgentEvaluationReport, T> field,
    T value,
  ) {
    switch (field.name) {
      case 'id':
        return copyWith(id: value as String);
      case 'at':
        return copyWith(at: value as DateTime);
      case 'suite':
        return copyWith(suite: value as String);
      case 'caseName':
        return copyWith(caseName: value as String);
      case 'outcome':
        return copyWith(outcome: value as String);
      case 'redactedTranscript':
        return copyWith(redactedTranscript: value as String?);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'AgentEvaluationReport has no settable field with this name',
        );
    }
  }

  AgentEvaluationReport copyWithAgentEvaluationReport({
    String? id,
    DateTime? at,
    String? suite,
    String? caseName,
    String? outcome,
    String? redactedTranscript,
  }) {
    return copyWith(
      id: id,
      at: at,
      suite: suite,
      caseName: caseName,
      outcome: outcome,
      redactedTranscript: redactedTranscript,
    );
  }

  AgentEvaluationReport patchWithAgentEvaluationReport([
    AgentEvaluationReportPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? AgentEvaluationReportPatch();
    final _patchMap = _patcher.patchMap;
    return AgentEvaluationReport(
      id: _patchMap.containsKey(AgentEvaluationReport$.id)
          ? ((_patchMap[AgentEvaluationReport$.id] is Function)
                    ? _patchMap[AgentEvaluationReport$.id](this.id)
                    : (_patchMap[AgentEvaluationReport$.id] is Patch)
                    ? _patchMap[AgentEvaluationReport$.id].applyTo(this.id)
                    : _patchMap[AgentEvaluationReport$.id])
                as String
          : this.id,
      at: _patchMap.containsKey(AgentEvaluationReport$.at)
          ? ((_patchMap[AgentEvaluationReport$.at] is Function)
                    ? _patchMap[AgentEvaluationReport$.at](this.at)
                    : (_patchMap[AgentEvaluationReport$.at] is Patch)
                    ? _patchMap[AgentEvaluationReport$.at].applyTo(this.at)
                    : _patchMap[AgentEvaluationReport$.at])
                as DateTime
          : this.at,
      suite: _patchMap.containsKey(AgentEvaluationReport$.suite)
          ? ((_patchMap[AgentEvaluationReport$.suite] is Function)
                    ? _patchMap[AgentEvaluationReport$.suite](this.suite)
                    : (_patchMap[AgentEvaluationReport$.suite] is Patch)
                    ? _patchMap[AgentEvaluationReport$.suite].applyTo(
                        this.suite,
                      )
                    : _patchMap[AgentEvaluationReport$.suite])
                as String
          : this.suite,
      caseName: _patchMap.containsKey(AgentEvaluationReport$.caseName)
          ? ((_patchMap[AgentEvaluationReport$.caseName] is Function)
                    ? _patchMap[AgentEvaluationReport$.caseName](this.caseName)
                    : (_patchMap[AgentEvaluationReport$.caseName] is Patch)
                    ? _patchMap[AgentEvaluationReport$.caseName].applyTo(
                        this.caseName,
                      )
                    : _patchMap[AgentEvaluationReport$.caseName])
                as String
          : this.caseName,
      outcome: _patchMap.containsKey(AgentEvaluationReport$.outcome)
          ? ((_patchMap[AgentEvaluationReport$.outcome] is Function)
                    ? _patchMap[AgentEvaluationReport$.outcome](this.outcome)
                    : (_patchMap[AgentEvaluationReport$.outcome] is Patch)
                    ? _patchMap[AgentEvaluationReport$.outcome].applyTo(
                        this.outcome,
                      )
                    : _patchMap[AgentEvaluationReport$.outcome])
                as String
          : this.outcome,
      redactedTranscript:
          _patchMap.containsKey(AgentEvaluationReport$.redactedTranscript)
          ? ((_patchMap[AgentEvaluationReport$.redactedTranscript] is Function)
                    ? _patchMap[AgentEvaluationReport$.redactedTranscript](
                        this.redactedTranscript,
                      )
                    : (_patchMap[AgentEvaluationReport$.redactedTranscript]
                          is Patch)
                    ? _patchMap[AgentEvaluationReport$.redactedTranscript]
                          .applyTo(this.redactedTranscript)
                    : _patchMap[AgentEvaluationReport$.redactedTranscript])
                as String?
          : this.redactedTranscript,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentEvaluationReport &&
        id == other.id &&
        at == other.at &&
        suite == other.suite &&
        caseName == other.caseName &&
        outcome == other.outcome &&
        redactedTranscript == other.redactedTranscript;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.at,
      this.suite,
      this.caseName,
      this.outcome,
      this.redactedTranscript,
    );
  }

  @override
  String toString() {
    return 'AgentEvaluationReport(' +
        'id: ${id}' +
        ', ' +
        'at: ${at}' +
        ', ' +
        'suite: ${suite}' +
        ', ' +
        'caseName: ${caseName}' +
        ', ' +
        'outcome: ${outcome}' +
        ', ' +
        'redactedTranscript: ${redactedTranscript})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentEvaluationReportToJson(this);
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

extension AgentEvaluationReportPropertyHelpers on AgentEvaluationReport {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasSuite {
    return this.suite.isNotEmpty;
  }

  bool get noSuite {
    return this.suite.isEmpty;
  }

  bool get hasCaseName {
    return this.caseName.isNotEmpty;
  }

  bool get noCaseName {
    return this.caseName.isEmpty;
  }

  bool get hasOutcome {
    return this.outcome.isNotEmpty;
  }

  bool get noOutcome {
    return this.outcome.isEmpty;
  }

  bool get hasRedactedTranscript {
    return this.redactedTranscript?.isNotEmpty == true;
  }

  bool get noRedactedTranscript {
    return this.redactedTranscript?.isEmpty ?? true;
  }

  String get redactedTranscriptRequired {
    return this.redactedTranscript ??
        (throw StateError('redactedTranscript is required but was null'));
  }
}

extension AgentEvaluationReportSerialization on AgentEvaluationReport {
  Map<String, dynamic> toJson() {
    return _$AgentEvaluationReportToJson(this);
  }
}

enum AgentEvaluationReport$ {
  id,
  at,
  suite,
  caseName,
  outcome,
  redactedTranscript,
}

class AgentEvaluationReportPatch
    extends PatchBase<AgentEvaluationReport, AgentEvaluationReport$> {
  AgentEvaluationReport applyTo(AgentEvaluationReport entity) {
    return entity.patchWithAgentEvaluationReport(this);
  }

  AgentEvaluationReportPatch withId(String? value) {
    patchMap[AgentEvaluationReport$.id] = value;
    return this;
  }

  AgentEvaluationReportPatch withAt(DateTime? value) {
    patchMap[AgentEvaluationReport$.at] = value;
    return this;
  }

  AgentEvaluationReportPatch withSuite(String? value) {
    patchMap[AgentEvaluationReport$.suite] = value;
    return this;
  }

  AgentEvaluationReportPatch withCaseName(String? value) {
    patchMap[AgentEvaluationReport$.caseName] = value;
    return this;
  }

  AgentEvaluationReportPatch withOutcome(String? value) {
    patchMap[AgentEvaluationReport$.outcome] = value;
    return this;
  }

  AgentEvaluationReportPatch withRedactedTranscript(String? value) {
    patchMap[AgentEvaluationReport$.redactedTranscript] = value;
    return this;
  }
}

/// Field descriptors for [AgentEvaluationReport] query construction
abstract final class AgentEvaluationReportFields {
  static const id = Field<AgentEvaluationReport, String>('id', _$id);

  static const at = Field<AgentEvaluationReport, DateTime>('at', _$at);

  static const suite = Field<AgentEvaluationReport, String>('suite', _$suite);

  static const caseName = Field<AgentEvaluationReport, String>(
    'caseName',
    _$caseName,
  );

  static const outcome = Field<AgentEvaluationReport, String>(
    'outcome',
    _$outcome,
  );

  static const redactedTranscript = Field<AgentEvaluationReport, String?>(
    'redactedTranscript',
    _$redactedTranscript,
  );

  static String _$id(AgentEvaluationReport e) {
    return e.id;
  }

  static DateTime _$at(AgentEvaluationReport e) {
    return e.at;
  }

  static String _$suite(AgentEvaluationReport e) {
    return e.suite;
  }

  static String _$caseName(AgentEvaluationReport e) {
    return e.caseName;
  }

  static String _$outcome(AgentEvaluationReport e) {
    return e.outcome;
  }

  static String? _$redactedTranscript(AgentEvaluationReport e) {
    return e.redactedTranscript;
  }
}

extension AgentEvaluationReportCompareE on AgentEvaluationReport {
  Map<String, dynamic> compareToAgentEvaluationReport(
    AgentEvaluationReport other,
  ) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (at != other.at) {
      diff['at'] = () => other.at;
    }

    if (suite != other.suite) {
      diff['suite'] = () => other.suite;
    }

    if (caseName != other.caseName) {
      diff['caseName'] = () => other.caseName;
    }

    if (outcome != other.outcome) {
      diff['outcome'] = () => other.outcome;
    }

    if (redactedTranscript != other.redactedTranscript) {
      diff['redactedTranscript'] = () => other.redactedTranscript;
    }
    return diff;
  }
}
