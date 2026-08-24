// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// The ToolResult value object — spec-exact from
// specs/003-tools-and-mcp/spec.md §Key Entities:
//   content (String), structuredPayload (Map?), artifactRef (ArtifactRef?)
//
// No `id` field. The spec defines ToolResult as an immutable composition of
// tool-output artifacts (no identity, no CRUD surface), so it is correctly
// modeled as a value object. zfa v6.0.0's `zfa make ToolResult repository
// usecase di mock provider service datasource` hard-requires an `id` field
// to scaffold the CRUD layers and aborts with a validation error instead
// of auto-detecting the value-object shape. This file ships the spec-exact
// value object in the consuming repo until zfa ships the matching fix.
//
// Pattern: same shape as ArtifactRef (PR #11 era entity) — plain Dart value
// object, no @Zorphy codegen, compiles without build_runner.

import '../../../domain/entities/artifact_ref/artifact_ref.dart';

/// ToolResult value object.
///
/// The model-facing result of a tool dispatch: textual `content` (always
/// present), optional `structuredPayload` for typed payloads the tool
/// emitted (e.g. JSON the engine can re-parse), and optional `artifactRef`
/// for oversized results that have been summarized and stored out-of-band
/// (per spec-003 §4.3 size discipline; PR #32's ArtifactProvider threshold
/// is the gate).
class ToolResult {
  /// Model-facing textual content. Always present, may be a summary
  /// (see [artifactRef]).
  final String content;

  /// Optional structured payload emitted by the tool — JSON the engine
  /// can re-parse to make decisions without round-tripping through the
  /// model. `null` for tools that only return free-form text.
  final Map<String, dynamic>? structuredPayload;

  /// Optional reference to an oversized artifact stored out-of-band. When
  /// non-null, [content] is a summary; the full body is retrievable via the
  /// artifact id.
  final ArtifactRef? artifactRef;

  const ToolResult({
    required this.content,
    this.structuredPayload,
    this.artifactRef,
  });

  /// True when this result carries an oversized artifact reference; the
  /// model-facing [content] is a summary, not the full body.
  bool get isSummarized => artifactRef != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolResult &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          _mapEq(structuredPayload, other.structuredPayload) &&
          artifactRef == other.artifactRef);

  static bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(content, artifactRef);

  @override
  String toString() =>
      'ToolResult(content: ${content.length > 60 ? '${content.substring(0, 60)}…' : content}, '
      'structuredPayload: ${structuredPayload == null ? 'null' : '{${structuredPayload!.length} keys}'}, '
      'artifactRef: $artifactRef)';
}
