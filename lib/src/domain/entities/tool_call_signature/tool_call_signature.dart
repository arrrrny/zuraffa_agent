// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#29.
//
// The ToolCallSignature value object. Content-addressable signature of a tool invocation: tool name + argument hash + version. Used by RepetitionTracker and the eval harness to dedupe calls.
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships a consistent
// value-object generator, this file may be regenerated with @Zorphy; until
// then it is the canonical source for the ToolCallSignature surface.

/// ToolCallSignature value object.
///
/// Content-addressable signature of a tool invocation: tool name + argument hash + version. Used by RepetitionTracker and the eval harness to dedupe calls.
class ToolCallSignature {
  final String id;

  const ToolCallSignature({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolCallSignature && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ToolCallSignature(id: $id)';
}
