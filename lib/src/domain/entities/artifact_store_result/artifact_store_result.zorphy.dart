// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'artifact_store_result.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ArtifactStoreResult {
  ArtifactStoreResult({
    required ArtifactRef this.ref,
    required bool this.summarized,
    String? this.summary,
  });

  factory ArtifactStoreResult.fromJson(Map<String, dynamic> json) =>
      _$ArtifactStoreResultFromJson(json);

  final ArtifactRef ref;

  final bool summarized;

  final String? summary;

  ArtifactStoreResult copyWith({
    ArtifactRef? ref,
    bool? summarized,
    String? summary,
  }) {
    return ArtifactStoreResult(
      ref: ref ?? this.ref,
      summarized: summarized ?? this.summarized,
      summary: summary ?? this.summary,
    );
  }

  ArtifactStoreResult copyWithArtifactStoreResult({
    ArtifactRef? ref,
    bool? summarized,
    String? summary,
  }) {
    return copyWith(ref: ref, summarized: summarized, summary: summary);
  }

  ArtifactStoreResult patchWithArtifactStoreResult([
    ArtifactStoreResultPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ArtifactStoreResultPatch();
    final _patchMap = _patcher.patchMap;
    return ArtifactStoreResult(
      ref: _patchMap.containsKey(ArtifactStoreResult$.ref)
          ? ((_patchMap[ArtifactStoreResult$.ref] is Function)
                    ? _patchMap[ArtifactStoreResult$.ref](this.ref)
                    : (_patchMap[ArtifactStoreResult$.ref] is Patch)
                    ? _patchMap[ArtifactStoreResult$.ref].applyTo(this.ref)
                    : _patchMap[ArtifactStoreResult$.ref])
                as ArtifactRef
          : this.ref,
      summarized: _patchMap.containsKey(ArtifactStoreResult$.summarized)
          ? ((_patchMap[ArtifactStoreResult$.summarized] is Function)
                    ? _patchMap[ArtifactStoreResult$.summarized](
                        this.summarized,
                      )
                    : (_patchMap[ArtifactStoreResult$.summarized] is Patch)
                    ? _patchMap[ArtifactStoreResult$.summarized].applyTo(
                        this.summarized,
                      )
                    : _patchMap[ArtifactStoreResult$.summarized])
                as bool
          : this.summarized,
      summary: _patchMap.containsKey(ArtifactStoreResult$.summary)
          ? ((_patchMap[ArtifactStoreResult$.summary] is Function)
                    ? _patchMap[ArtifactStoreResult$.summary](this.summary)
                    : (_patchMap[ArtifactStoreResult$.summary] is Patch)
                    ? _patchMap[ArtifactStoreResult$.summary].applyTo(
                        this.summary,
                      )
                    : _patchMap[ArtifactStoreResult$.summary])
                as String?
          : this.summary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtifactStoreResult &&
        ref == other.ref &&
        summarized == other.summarized &&
        summary == other.summary;
  }

  @override
  int get hashCode {
    return Object.hash(this.ref, this.summarized, this.summary);
  }

  @override
  String toString() {
    return 'ArtifactStoreResult(' +
        'ref: ${ref}' +
        ', ' +
        'summarized: ${summarized}' +
        ', ' +
        'summary: ${summary})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ArtifactStoreResultToJson(this);
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

extension ArtifactStoreResultPropertyHelpers on ArtifactStoreResult {
  bool get hasSummary {
    return this.summary?.isNotEmpty == true;
  }

  bool get noSummary {
    return this.summary?.isEmpty ?? true;
  }

  String get summaryRequired {
    return this.summary ??
        (throw StateError('summary is required but was null'));
  }
}

extension ArtifactStoreResultSerialization on ArtifactStoreResult {
  Map<String, dynamic> toJson() {
    return _$ArtifactStoreResultToJson(this);
  }
}

enum ArtifactStoreResult$ { ref, summarized, summary }

class ArtifactStoreResultPatch
    extends PatchBase<ArtifactStoreResult, ArtifactStoreResult$> {
  ArtifactStoreResult applyTo(ArtifactStoreResult entity) {
    return entity.patchWithArtifactStoreResult(this);
  }

  ArtifactStoreResultPatch withRef(ArtifactRef? value) {
    patchMap[ArtifactStoreResult$.ref] = value;
    return this;
  }

  ArtifactStoreResultPatch withRefPatch(ArtifactRefPatch patch) {
    patchMap[ArtifactStoreResult$.ref] = patch;
    return this;
  }

  ArtifactStoreResultPatch withRefPatchFunc(
    ArtifactRefPatch Function(ArtifactRefPatch) patch,
  ) {
    patchMap[ArtifactStoreResult$.ref] = (dynamic current) {
      var currentPatch = ArtifactRefPatch();
      return patch(currentPatch).applyTo(current as ArtifactRef);
    };
    return this;
  }

  ArtifactStoreResultPatch withSummarized(bool? value) {
    patchMap[ArtifactStoreResult$.summarized] = value;
    return this;
  }

  ArtifactStoreResultPatch withSummary(String? value) {
    patchMap[ArtifactStoreResult$.summary] = value;
    return this;
  }
}

/// Field descriptors for [ArtifactStoreResult] query construction
abstract final class ArtifactStoreResultFields {
  static const ref = Field<ArtifactStoreResult, ArtifactRef>('ref', _$ref);

  static const summarized = Field<ArtifactStoreResult, bool>(
    'summarized',
    _$summarized,
  );

  static const summary = Field<ArtifactStoreResult, String?>(
    'summary',
    _$summary,
  );

  static ArtifactRef _$ref(ArtifactStoreResult e) {
    return e.ref;
  }

  static bool _$summarized(ArtifactStoreResult e) {
    return e.summarized;
  }

  static String? _$summary(ArtifactStoreResult e) {
    return e.summary;
  }
}

extension ArtifactStoreResultCompareE on ArtifactStoreResult {
  Map<String, dynamic> compareToArtifactStoreResult(ArtifactStoreResult other) {
    final Map<String, dynamic> diff = {};

    if (ref != other.ref) {
      diff['ref'] = () => other.ref;
    }

    if (summarized != other.summarized) {
      diff['summarized'] = () => other.summarized;
    }

    if (summary != other.summary) {
      diff['summary'] = () => other.summary;
    }
    return diff;
  }
}
