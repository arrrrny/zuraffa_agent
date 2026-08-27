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

  AgentMessage({
    required this.id,
    required this.role,
    required this.parts,
  }) {
    // Construction-time validation (spec 041, FR-001): a message without
    // identity or role is unaddressable in the session tree.
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (role.isEmpty) {
      throw ArgumentError.value(role, 'role', 'must not be empty');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          _partsEq(parts, other.parts));

  /// Element-wise parts equality (spec 041, FR-002): Dart's List == and
  /// Map == are identity, so distinct-but-equal part instances used to
  /// compare unequal — breaking dedup and replay comparison. Parts compare
  /// with their own ==, deep-walking embedded Maps/Lists the same way
  /// UiTreePayload._deepEq does; other object types fall back to their own
  /// == (documented in the spec).
  static bool _partsEq(List<Object> a, List<Object> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEq(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _deepEq(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEq(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(id, role, _deepHash(parts));

  /// Hash consistent with [_deepEq]: embedded Maps/Lists hash by content
  /// (their default hashCode is identity-based, which would make
  /// deep-equal messages hash differently and violate the ==/hashCode
  /// contract).
  static int _deepHash(Object? value) {
    if (value == null) return 0;
    if (value is Map) {
      final keys = value.keys.toList()..sort();
      return Object.hashAll([
        for (final key in keys) Object.hash(key, _deepHash(value[key])),
      ]);
    }
    if (value is List) {
      return Object.hashAll([for (final item in value) _deepHash(item)]);
    }
    return value.hashCode;
  }

  @override
  String toString() =>
      'AgentMessage(id: $id, role: $role, parts: $parts)';
}
