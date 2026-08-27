// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// The ToolResult value object — spec-exact from
// specs/003-tools-and-mcp/spec.md §Key Entities:
//   content (String), structuredPayload (Map?), artifactRef (ArtifactRef?)
//
// No `id` field. The spec defines ToolResult as an immutable composition of
// tool-output artifacts (no identity, no CRUD surface), so it is correctly
// modeled as a value object. zfa v6.0.0's `zfa make ToolResult ...` hard-
// requires an `id` field to scaffold the CRUD layers and aborts with a
// validation error instead of auto-detecting the value-object shape. This
// file ships the spec-exact value object in the consuming repo until zfa
// ships the matching fix.
//
// Refined under specs/031-tool-result-value-object (TDD): the value-object
// semantics the task names — success/error discrimination (isError +
// success/error/oversized factories), JSON round-trip serialization
// (toJson/fromJson with nested artifactRef), oversized-result handling
// (summarize + artifactRef per spec-003 §4.3), and a hashCode that folds
// the payload in order-independently (the scaffold hashed only content +
// artifactRef — contract-legal, but payload-only differences collided 100%
// of the time; the refined fold gives unequal results distinct hashes).
//
// Pattern: same shape as ArtifactRef (PR #11 era entity) — plain Dart value
// object, no @Zorphy codegen, compiles without build_runner.

import '../../../domain/entities/artifact_ref/artifact_ref.dart';

/// ToolResult value object.
///
/// The model-facing result of a tool dispatch: textual `content` (always
/// present), optional `structuredPayload` for typed payloads the tool
/// emitted (e.g. JSON the engine can re-parse), optional `artifactRef` for
/// oversized results that have been summarized and stored out-of-band (per
/// spec-003 §4.3 size discipline), and `isError` marking typed failure
/// surfaces (MCP transport errors, tool crashes, denied approvals).
class ToolResult {
  /// Model-facing textual content. Always present, may be a summary
  /// (see [artifactRef]) or an error message (see [isError]).
  final String content;

  /// Optional structured payload emitted by the tool — JSON the engine
  /// can re-parse to make decisions without round-tripping through the
  /// model. `null` for tools that only return free-form text.
  final Map<String, dynamic>? structuredPayload;

  /// Optional reference to an oversized artifact stored out-of-band. When
  /// non-null, [content] is a summary; the full body is retrievable via the
  /// artifact id.
  final ArtifactRef? artifactRef;

  /// True when this result is a typed failure surface (transport error,
  /// tool crash, denied approval). Defaults to false.
  final bool isError;

  const ToolResult({
    required this.content,
    this.structuredPayload,
    this.artifactRef,
    this.isError = false,
  });

  /// Constructs a success result — the model should act on [content].
  const ToolResult.success({
    required String content,
    Map<String, dynamic>? structuredPayload,
    ArtifactRef? artifactRef,
  }) : this(
          content: content,
          structuredPayload: structuredPayload,
          artifactRef: artifactRef,
        );

  /// Constructs an error result — [content] carries the failure message
  /// for the model; [structuredPayload] may carry typed error details.
  const ToolResult.error({
    required String content,
    Map<String, dynamic>? structuredPayload,
    ArtifactRef? artifactRef,
  }) : this(
          content: content,
          structuredPayload: structuredPayload,
          artifactRef: artifactRef,
          isError: true,
        );

  /// Constructs an oversized result (spec-003 §4.3): the full body lives
  /// behind [artifactRef]; the model-facing [summary] is bounded by the
  /// OversizedResultPolicy (spec 050). An oversized error body is also
  /// allowed ([isError]).
  const ToolResult.oversized({
    required String summary,
    required ArtifactRef artifactRef,
    Map<String, dynamic>? structuredPayload,
    bool isError = false,
  }) : this(
          content: summary,
          structuredPayload: structuredPayload,
          artifactRef: artifactRef,
          isError: isError,
        );

  /// True when this result carries an oversized artifact reference; the
  /// model-facing [content] is a summary, not the full body.
  bool get isSummarized => artifactRef != null;

  /// Serializes to a JSON map: `content` always; `structuredPayload` and
  /// `artifactRef` only when present (never fabricating empty structure);
  /// `isError` always. The artifactRef shape matches ArtifactRef's
  /// generated JSON: `{kind, id, uri?}`.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'content': content,
      'isError': isError,
    };
    final payload = structuredPayload;
    if (payload != null) json['structuredPayload'] = payload;
    final ref = artifactRef;
    if (ref != null) {
      json['artifactRef'] = <String, dynamic>{
        'kind': ref.kind,
        'id': ref.id,
        if (ref.uri != null) 'uri': ref.uri,
      };
    }
    return json;
  }

  /// Parses a [ToolResult] from its JSON shape (see [toJson]). A missing
  /// `structuredPayload`/`artifactRef` stays null; a non-map payload is a
  /// contract violation and throws [ArgumentError].
  factory ToolResult.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['structuredPayload'];
    if (rawPayload != null && rawPayload is! Map) {
      throw ArgumentError.value(
        rawPayload,
        'structuredPayload',
        'ToolResult structuredPayload must be a JSON object or absent',
      );
    }
    final rawRef = json['artifactRef'];
    if (rawRef != null && rawRef is! Map) {
      throw ArgumentError.value(
        rawRef,
        'artifactRef',
        'ToolResult artifactRef must be a JSON object or absent',
      );
    }
    return ToolResult(
      content: json['content'] as String,
      structuredPayload: rawPayload == null
          ? null
          : Map<String, dynamic>.from(rawPayload as Map),
      artifactRef: rawRef == null
          ? null
          : ArtifactRef(
              kind: (rawRef as Map)['kind'] as String,
              id: rawRef['id'] as String,
              uri: rawRef['uri'] as String?,
            ),
      isError: (json['isError'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolResult &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          _mapEq(structuredPayload, other.structuredPayload) &&
          artifactRef == other.artifactRef &&
          isError == other.isError);

  static bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// Hash consistent with [==]: content, isError, artifactRef, plus an
  /// order-independent fold over the payload entries. The scaffold hashed
  /// only content + artifactRef — contract-legal, but unequal results
  /// differing only in payload always collided; the commutative fold
  /// (sum of per-entry hashes) gives them distinct hashes while keeping
  /// equal results (any insertion order, any map instance) equal.
  @override
  int get hashCode {
    var payloadHash = 0;
    final payload = structuredPayload;
    if (payload != null) {
      for (final entry in payload.entries) {
        // Sum is commutative: insertion order cannot change the result.
        payloadHash += Object.hash(entry.key, entry.value);
      }
    }
    return Object.hash(content, isError, artifactRef, payloadHash);
  }

  @override
  String toString() =>
      'ToolResult(content: ${content.length > 60 ? '${content.substring(0, 60)}…' : content}, '
      'structuredPayload: ${structuredPayload == null ? 'null' : '{${structuredPayload!.length} keys}'}, '
      'artifactRef: $artifactRef, isError: $isError)';
}
