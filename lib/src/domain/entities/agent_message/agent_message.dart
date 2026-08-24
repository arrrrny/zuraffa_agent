// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// AgentMessage (multimodal parts) value object - spec-exact from epic #1 §R1 (issue #3).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// AgentMessage (multimodal parts) value object.
///
/// Multimodal assistant/user message — text, image, audio, document parts — ported from pi_agent's types.dart (epic #1 §R2.1, issue #3). The atomic conversational unit the engine assembles into turns.
class AgentMessage {
  final String id;
  final String role;
  final List<Object> parts;

  const AgentMessage({
    required this.id,
    required this.role,
    required this.parts,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentMessage &&
          runtimeType == other.runtimeType && id == other.id && role == other.role && parts == other.parts);

  @override
  int get hashCode => Object.hash(id, role, parts);

  @override
  String toString() =>
      'AgentMessage(id: $id, role: $role, parts: $parts)';
}
