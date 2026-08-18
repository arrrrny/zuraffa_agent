// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'compaction_summary.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class CompactionSummary {
  CompactionSummary({
    required List<String> this.decisions,
    required List<String> this.toolNames,
    required List<String> this.keyResults,
    String? this.planState,
  });

  factory CompactionSummary.fromJson(Map<String, dynamic> json) =>
      _$CompactionSummaryFromJson(json);

  final List<String> decisions;

  final List<String> toolNames;

  final List<String> keyResults;

  final String? planState;

  CompactionSummary copyWith({
    List<String>? decisions,
    List<String>? toolNames,
    List<String>? keyResults,
    String? planState,
  }) {
    return CompactionSummary(
      decisions: decisions ?? this.decisions,
      toolNames: toolNames ?? this.toolNames,
      keyResults: keyResults ?? this.keyResults,
      planState: planState ?? this.planState,
    );
  }

  CompactionSummary copyWithCompactionSummary({
    List<String>? decisions,
    List<String>? toolNames,
    List<String>? keyResults,
    String? planState,
  }) {
    return copyWith(
      decisions: decisions,
      toolNames: toolNames,
      keyResults: keyResults,
      planState: planState,
    );
  }

  CompactionSummary patchWithCompactionSummary([
    CompactionSummaryPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? CompactionSummaryPatch();
    final _patchMap = _patcher.patchMap;
    return CompactionSummary(
      decisions: _patchMap.containsKey(CompactionSummary$.decisions)
          ? (_patchMap[CompactionSummary$.decisions] is Function)
                ? _patchMap[CompactionSummary$.decisions](this.decisions)
                : (_patchMap[CompactionSummary$.decisions] is Patch)
                ? _patchMap[CompactionSummary$.decisions].applyTo(
                    this.decisions,
                  )
                : _patchMap[CompactionSummary$.decisions]
          : this.decisions,
      toolNames: _patchMap.containsKey(CompactionSummary$.toolNames)
          ? (_patchMap[CompactionSummary$.toolNames] is Function)
                ? _patchMap[CompactionSummary$.toolNames](this.toolNames)
                : (_patchMap[CompactionSummary$.toolNames] is Patch)
                ? _patchMap[CompactionSummary$.toolNames].applyTo(
                    this.toolNames,
                  )
                : _patchMap[CompactionSummary$.toolNames]
          : this.toolNames,
      keyResults: _patchMap.containsKey(CompactionSummary$.keyResults)
          ? (_patchMap[CompactionSummary$.keyResults] is Function)
                ? _patchMap[CompactionSummary$.keyResults](this.keyResults)
                : (_patchMap[CompactionSummary$.keyResults] is Patch)
                ? _patchMap[CompactionSummary$.keyResults].applyTo(
                    this.keyResults,
                  )
                : _patchMap[CompactionSummary$.keyResults]
          : this.keyResults,
      planState: _patchMap.containsKey(CompactionSummary$.planState)
          ? (_patchMap[CompactionSummary$.planState] is Function)
                ? _patchMap[CompactionSummary$.planState](this.planState)
                : (_patchMap[CompactionSummary$.planState] is Patch)
                ? _patchMap[CompactionSummary$.planState].applyTo(
                    this.planState,
                  )
                : _patchMap[CompactionSummary$.planState]
          : this.planState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompactionSummary &&
        decisions == other.decisions &&
        toolNames == other.toolNames &&
        keyResults == other.keyResults &&
        planState == other.planState;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.decisions,
      this.toolNames,
      this.keyResults,
      this.planState,
    );
  }

  @override
  String toString() {
    return 'CompactionSummary(' +
        'decisions: ${decisions}' +
        ', ' +
        'toolNames: ${toolNames}' +
        ', ' +
        'keyResults: ${keyResults}' +
        ', ' +
        'planState: ${planState})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompactionSummaryToJson(this);
    return _sanitizeJson(data);
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

extension CompactionSummaryPropertyHelpers on CompactionSummary {
  bool get hasDecisions {
    return this.decisions.isNotEmpty;
  }

  bool get noDecisions {
    return this.decisions.isEmpty;
  }

  bool get hasToolNames {
    return this.toolNames.isNotEmpty;
  }

  bool get noToolNames {
    return this.toolNames.isEmpty;
  }

  bool get hasKeyResults {
    return this.keyResults.isNotEmpty;
  }

  bool get noKeyResults {
    return this.keyResults.isEmpty;
  }

  bool get hasPlanState {
    return this.planState?.isNotEmpty == true;
  }

  bool get noPlanState {
    return this.planState?.isEmpty ?? true;
  }

  String get planStateRequired {
    return this.planState ??
        (throw StateError('planState is required but was null'));
  }
}

extension CompactionSummarySerialization on CompactionSummary {
  Map<String, dynamic> toJson() {
    return _$CompactionSummaryToJson(this);
  }
}

enum CompactionSummary$ { decisions, toolNames, keyResults, planState }

class CompactionSummaryPatch
    extends PatchBase<CompactionSummary, CompactionSummary$> {
  CompactionSummary applyTo(CompactionSummary entity) {
    return entity.patchWithCompactionSummary(this);
  }

  CompactionSummaryPatch withDecisions(List<String>? value) {
    patchMap[CompactionSummary$.decisions] = value;
    return this;
  }

  CompactionSummaryPatch withToolNames(List<String>? value) {
    patchMap[CompactionSummary$.toolNames] = value;
    return this;
  }

  CompactionSummaryPatch withKeyResults(List<String>? value) {
    patchMap[CompactionSummary$.keyResults] = value;
    return this;
  }

  CompactionSummaryPatch withPlanState(String? value) {
    patchMap[CompactionSummary$.planState] = value;
    return this;
  }
}

/// Field descriptors for [CompactionSummary] query construction
abstract final class CompactionSummaryFields {
  static const decisions = Field<CompactionSummary, List<String>>(
    'decisions',
    _$decisions,
  );

  static const toolNames = Field<CompactionSummary, List<String>>(
    'toolNames',
    _$toolNames,
  );

  static const keyResults = Field<CompactionSummary, List<String>>(
    'keyResults',
    _$keyResults,
  );

  static const planState = Field<CompactionSummary, String?>(
    'planState',
    _$planState,
  );

  static List<String> _$decisions(CompactionSummary e) {
    return e.decisions;
  }

  static List<String> _$toolNames(CompactionSummary e) {
    return e.toolNames;
  }

  static List<String> _$keyResults(CompactionSummary e) {
    return e.keyResults;
  }

  static String? _$planState(CompactionSummary e) {
    return e.planState;
  }
}

extension CompactionSummaryCompareE on CompactionSummary {
  Map<String, dynamic> compareToCompactionSummary(CompactionSummary other) {
    final Map<String, dynamic> diff = {};

    if (decisions != other.decisions) {
      diff['decisions'] = () => other.decisions;
    }

    if (toolNames != other.toolNames) {
      diff['toolNames'] = () => other.toolNames;
    }

    if (keyResults != other.keyResults) {
      diff['keyResults'] = () => other.keyResults;
    }

    if (planState != other.planState) {
      diff['planState'] = () => other.planState;
    }
    return diff;
  }
}
