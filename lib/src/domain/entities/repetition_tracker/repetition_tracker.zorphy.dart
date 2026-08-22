// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'repetition_tracker.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class RepetitionTracker {
  RepetitionTracker({
    String? id,
    required Map<String, int> this.callSignatures,
    required List<String> this.recentCalls,
  }) : this.id = id ?? const Uuid().v4();

  factory RepetitionTracker.fromJson(Map<String, dynamic> json) =>
      _$RepetitionTrackerFromJson(json);

  final String id;

  final Map<String, int> callSignatures;

  final List<String> recentCalls;

  RepetitionTracker copyWith({
    String? id,
    Map<String, int>? callSignatures,
    List<String>? recentCalls,
  }) {
    return RepetitionTracker(
      id: id ?? this.id,
      callSignatures: callSignatures ?? this.callSignatures,
      recentCalls: recentCalls ?? this.recentCalls,
    );
  }

  RepetitionTracker copyWithRepetitionTracker({
    String? id,
    Map<String, int>? callSignatures,
    List<String>? recentCalls,
  }) {
    return copyWith(
      id: id,
      callSignatures: callSignatures,
      recentCalls: recentCalls,
    );
  }

  RepetitionTracker patchWithRepetitionTracker([
    RepetitionTrackerPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? RepetitionTrackerPatch();
    final _patchMap = _patcher.patchMap;
    return RepetitionTracker(
      id: _patchMap.containsKey(RepetitionTracker$.id)
          ? ((_patchMap[RepetitionTracker$.id] is Function)
                    ? _patchMap[RepetitionTracker$.id](this.id)
                    : (_patchMap[RepetitionTracker$.id] is Patch)
                    ? _patchMap[RepetitionTracker$.id].applyTo(this.id)
                    : _patchMap[RepetitionTracker$.id])
                as String
          : this.id,
      callSignatures: _patchMap.containsKey(RepetitionTracker$.callSignatures)
          ? ((_patchMap[RepetitionTracker$.callSignatures] is Function)
                    ? _patchMap[RepetitionTracker$.callSignatures](
                        this.callSignatures,
                      )
                    : (_patchMap[RepetitionTracker$.callSignatures] is Patch)
                    ? _patchMap[RepetitionTracker$.callSignatures].applyTo(
                        this.callSignatures,
                      )
                    : _patchMap[RepetitionTracker$.callSignatures])
                as Map<String, int>
          : this.callSignatures,
      recentCalls: _patchMap.containsKey(RepetitionTracker$.recentCalls)
          ? ((_patchMap[RepetitionTracker$.recentCalls] is Function)
                    ? _patchMap[RepetitionTracker$.recentCalls](
                        this.recentCalls,
                      )
                    : (_patchMap[RepetitionTracker$.recentCalls] is Patch)
                    ? _patchMap[RepetitionTracker$.recentCalls].applyTo(
                        this.recentCalls,
                      )
                    : _patchMap[RepetitionTracker$.recentCalls])
                as List<String>
          : this.recentCalls,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepetitionTracker &&
        id == other.id &&
        callSignatures == other.callSignatures &&
        recentCalls == other.recentCalls;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.callSignatures, this.recentCalls);
  }

  @override
  String toString() {
    return 'RepetitionTracker(' +
        'id: ${id}' +
        ', ' +
        'callSignatures: ${callSignatures}' +
        ', ' +
        'recentCalls: ${recentCalls})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RepetitionTrackerToJson(this);
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

extension RepetitionTrackerPropertyHelpers on RepetitionTracker {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasCallSignatures {
    return this.callSignatures.isNotEmpty;
  }

  bool get noCallSignatures {
    return this.callSignatures.isEmpty;
  }

  bool get hasRecentCalls {
    return this.recentCalls.isNotEmpty;
  }

  bool get noRecentCalls {
    return this.recentCalls.isEmpty;
  }
}

extension RepetitionTrackerSerialization on RepetitionTracker {
  Map<String, dynamic> toJson() {
    return _$RepetitionTrackerToJson(this);
  }
}

enum RepetitionTracker$ { id, callSignatures, recentCalls }

class RepetitionTrackerPatch
    extends PatchBase<RepetitionTracker, RepetitionTracker$> {
  RepetitionTracker applyTo(RepetitionTracker entity) {
    return entity.patchWithRepetitionTracker(this);
  }

  RepetitionTrackerPatch withId(String? value) {
    patchMap[RepetitionTracker$.id] = value;
    return this;
  }

  RepetitionTrackerPatch withCallSignatures(Map<String, int>? value) {
    patchMap[RepetitionTracker$.callSignatures] = value;
    return this;
  }

  RepetitionTrackerPatch withRecentCalls(List<String>? value) {
    patchMap[RepetitionTracker$.recentCalls] = value;
    return this;
  }
}

/// Field descriptors for [RepetitionTracker] query construction
abstract final class RepetitionTrackerFields {
  static const id = Field<RepetitionTracker, String>('id', _$id);

  static const callSignatures = Field<RepetitionTracker, Map<String, int>>(
    'callSignatures',
    _$callSignatures,
  );

  static const recentCalls = Field<RepetitionTracker, List<String>>(
    'recentCalls',
    _$recentCalls,
  );

  static String _$id(RepetitionTracker e) {
    return e.id;
  }

  static Map<String, int> _$callSignatures(RepetitionTracker e) {
    return e.callSignatures;
  }

  static List<String> _$recentCalls(RepetitionTracker e) {
    return e.recentCalls;
  }
}

extension RepetitionTrackerCompareE on RepetitionTracker {
  Map<String, dynamic> compareToRepetitionTracker(RepetitionTracker other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (callSignatures != other.callSignatures) {
      diff['callSignatures'] = () => other.callSignatures;
    }

    if (recentCalls != other.recentCalls) {
      diff['recentCalls'] = () => other.recentCalls;
    }
    return diff;
  }
}
