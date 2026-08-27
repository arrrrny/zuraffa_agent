// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#29.
//
// The ToolCallSignature value object. Content-addressable signature of a tool
// invocation: tool name + argument hash + version. Used by RepetitionTracker
// and the eval harness to dedupe calls.
//
// Refined under specs/29-tool_call_signature-datasource-pair (TDD cycle 1):
// the anemic id-only scaffold became the content-addressable identity —
// toolName + argumentHash + version with the canonical key derived from
// content ('toolName@version:argumentHash'). Equality and hashCode use the
// content triple only, so a legacy explicit id can never create phantom
// inequality between content-equal signatures.
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner.

/// ToolCallSignature value object.
///
/// Content-addressable signature of a tool invocation: tool name + argument
/// hash + version. Two invocations with the same content produce equal
/// signatures with identical [key]s — the basis of caching and dedup.
class ToolCallSignature {
  /// Canonical content-derived key: `toolName@version:argumentHash`.
  ///
  /// Kept as [id] for backward compatibility with the anemic scaffold; a
  /// legacy explicit [id] is preserved verbatim but does not participate in
  /// equality.
  final String id;

  /// Tool name (namespaced where sources collide, e.g. 'webview.browse').
  final String toolName;

  /// Opaque hash of the invocation arguments — produced by the caller;
  /// this object never re-hashes.
  final String argumentHash;

  /// Tool version — part of the content so a version bump invalidates
  /// dedup. Defaults to 1.
  final int version;

  const ToolCallSignature({
    String? id,
    this.toolName = '',
    this.argumentHash = '',
    this.version = 1,
  }) : id = id ?? '$toolName@$version:$argumentHash';

  /// The canonical content-derived key this signature addresses.
  String get key => '$toolName@$version:$argumentHash';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolCallSignature &&
          runtimeType == other.runtimeType &&
          toolName == other.toolName &&
          argumentHash == other.argumentHash &&
          version == other.version);

  @override
  int get hashCode => Object.hash(toolName, argumentHash, version);

  @override
  String toString() =>
      'ToolCallSignature(toolName: $toolName, argumentHash: $argumentHash, '
      'version: $version, key: $key)';
}
