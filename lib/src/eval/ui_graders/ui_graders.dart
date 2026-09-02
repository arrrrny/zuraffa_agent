// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI).
//
// UI tree graders for the eval harness — issue #8 §4 ("Eval graders"):
// schema-grader variant for UI trees (validates against the pinned
// vocabulary) + snapshot grader (byte-stable canonical JSON diff).
//
// Both graders implement a common [UiGrader] interface so the eval
// harness can swap them in where it currently uses [GraderSealed]. The
// engine stays UI-framework-agnostic (issue #8 §6): the graders operate
// on the [UiTreePayload] value object, never on rendered pixels. Golden
// missions can assert on rendered-intent (tree shape/props) without
// pixels — golden-mission GM-6 (dws_playground) uses this (issue #8 §4).
//
// Plain Dart, no @Zorphy codegen, compiles without build_runner.

import 'dart:convert';

import '../../domain/entities/ui_spec/ui_spec.dart';
import '../../domain/entities/ui_tree_payload/ui_tree_payload.dart';

/// A single graded UI tree's verdict — produced by [UiGrader.grade].
class UiGradeResult {
  /// True when the payload passed the grader's check.
  final bool passed;

  /// Human-readable verdict — either 'PASS' or a colon-joined list of
  /// failure reasons (one per failing check).
  final String detail;

  const UiGradeResult.passed() : passed = true, detail = 'PASS';

  const UiGradeResult.failed(this.detail) : passed = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiGradeResult &&
          runtimeType == other.runtimeType &&
          passed == other.passed &&
          detail == other.detail);

  @override
  int get hashCode => Object.hash(passed, detail);

  @override
  String toString() => 'UiGradeResult(passed: $passed, detail: $detail)';
}

/// Common interface for UI tree graders (issue #8 §4).
abstract class UiGrader {
  /// Grade [payload] against this grader's pinned expectation.
  ///
  /// Returns [UiGradeResult.passed] when the payload satisfies the
  /// grader; [UiGradeResult.failed] with a colon-joined reason list
  /// otherwise. The grader MUST be pure: no I/O, no global state, no
  /// clock — the same payload + pinned expectation yields the same
  /// verdict on every call (replayability, per issue #8 §5).
  UiGradeResult grade(UiTreePayload payload);
}

/// Schema grader — validates a [UiTreePayload] against a pinned
/// [UiSpec] (issue #8 §4: "schema-grader variant for UI trees").
///
/// The grader is a thin adapter over [UiSpec.validatePayload]: it returns
/// [UiGradeResult.passed] when the payload is in-pin, or
/// [UiGradeResult.failed] with a colon-joined list of
/// [UiVocabularyPinError.reason]s otherwise. The pin covers vocabulary
/// match, allowedComponents, and caps (depth/nodes).
class UiSchemaGrader implements UiGrader {
  final UiSpec pinned;

  const UiSchemaGrader(this.pinned);

  @override
  UiGradeResult grade(UiTreePayload payload) {
    final errors = pinned.validatePayload(payload);
    if (errors.isEmpty) return const UiGradeResult.passed();
    return UiGradeResult.failed(
      errors.map((UiVocabularyPinError e) => e.reason).join('; '),
    );
  }
}

/// Snapshot grader — byte-stable canonical JSON diff (issue #8 §4:
/// "snapshot grader (byte-stable canonical JSON diff)").
///
/// The grader canonicalizes both the pinned expected payload and the
/// actual payload to a deterministic JSON form (keys sorted
/// recursively, no insignificant whitespace, UTF-8) and compares the
/// canonical strings byte-for-byte. Equal payloads produce equal
/// canonical forms regardless of insertion order or map instance — the
/// snapshot is byte-stable across runs.
///
/// The canonical form is produced by [canonicalize] — a recursive
/// key-sorting walk that produces a `Map<String, dynamic>` whose keys
/// are sorted at every level, then `jsonEncode`d with no padding.
class UiSnapshotGrader implements UiGrader {
  /// The pinned expected payload. Stored as the canonical JSON string
  /// at construction so the grader's verdict is byte-stable even if the
  /// caller later mutates the source map.
  final String _expectedCanonical;

  /// Construct from a pinned expected [payload]. The payload is
  /// canonicalized at construction.
  UiSnapshotGrader(UiTreePayload payload)
    : _expectedCanonical = canonicalize(payload.toJson());

  /// Construct from a pre-canonicalized JSON string (e.g. read from a
  /// golden-mission cassette). The string is stored as-is — no
  /// re-canonicalization — so the cassette's stored form is the
  /// ground truth.
  UiSnapshotGrader.fromCanonical(String canonicalJson)
    : _expectedCanonical = canonicalJson;

  @override
  UiGradeResult grade(UiTreePayload payload) {
    final actualCanonical = canonicalize(payload.toJson());
    if (actualCanonical == _expectedCanonical) {
      return const UiGradeResult.passed();
    }
    return UiGradeResult.failed(
      'snapshot mismatch: canonical JSON differs from pinned expected',
    );
  }

  /// Canonicalize a JSON-compatible value to a deterministic string
  /// (issue #8 §4: "byte-stable canonical JSON diff").
  ///
  /// Rules:
  /// - Maps: keys sorted ascending at every level, then encoded as
  ///   `{"k1":v1,"k2":v2,...}` with no insignificant whitespace.
  /// - Lists: encoded in index order.
  /// - Primitives: encoded per [JsonEncoder] (strings quoted, numbers
  ///   bare, booleans/null bare).
  /// - The encoder uses no padding (`JsonEncoder.withIndent(null)`).
  static String canonicalize(Object? value) {
    final sorted = _sortKeys(value);
    return json.encode(sorted);
  }

  static Object? _sortKeys(Object? value) {
    if (value is Map<String, dynamic>) {
      final keys = value.keys.toList()..sort();
      final out = <String, dynamic>{};
      for (final k in keys) {
        out[k] = _sortKeys(value[k]);
      }
      return out;
    }
    if (value is Map) {
      // Non-String-keyed map: stringify keys, sort, then re-walk.
      final keys = value.keys.map((Object? k) => '$k').toList()..sort();
      final out = <String, dynamic>{};
      for (final k in keys) {
        // The original map's value for the stringified key — best
        // effort for non-string maps; UI trees are string-keyed.
        out[k] = _sortKeys(value[k]);
      }
      return out;
    }
    if (value is List) {
      return [for (final v in value) _sortKeys(v)];
    }
    return value;
  }
}
