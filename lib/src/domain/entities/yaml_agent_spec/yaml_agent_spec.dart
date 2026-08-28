// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// YamlAgentSpec (declarative + extends) value object - spec-exact from epic #1 §R5 (issue #6).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// YamlAgentSpec (declarative + extends) value object.
///
/// Declarative YAML agent spec — extends inheritance, validation diagnostics, declarative tool allowlist + steering (epic #5 §R5.3, issue #6 US3).
class YamlAgentSpec {
  final String id;
  final String name;
  final String? extendsSpecId;
  final List<String> toolAllowlist;
  final String systemPrompt;

  const YamlAgentSpec({
    required this.id,
    required this.name,
    this.extendsSpecId,
    required this.toolAllowlist,
    required this.systemPrompt,
  });

  /// Validation diagnostics for a declarative spec.
  ///
  /// Returns the list of precise errors (empty when the spec is valid).
  /// [parentOf] maps a spec id to its parent spec id (or null); [knownTools]
  /// is the set of tool names the agent is allowed to reference.
  List<String> validate({
    required Map<String, String?> parentOf,
    required Set<String> knownTools,
  }) {
    final errors = <String>[];
    for (final tool in toolAllowlist) {
      if (!knownTools.contains(tool)) {
        errors.add("unknown tool '$tool' referenced by spec '$id'");
      }
    }
    if (extendsSpecId != null && !parentOf.containsKey(extendsSpecId)) {
      errors.add("unknown parent spec '$extendsSpecId' referenced by spec '$id'");
    }
    final chain = <String>[];
    var current = extendsSpecId;
    while (current != null) {
      if (chain.contains(current)) {
        errors.add("cyclic inheritance in spec '$id': ${[...chain, current].join(' -> ')}");
        break;
      }
      chain.add(current);
      current = parentOf[current];
    }
    return errors;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YamlAgentSpec &&
          runtimeType == other.runtimeType && id == other.id && name == other.name && extendsSpecId == other.extendsSpecId && toolAllowlist == other.toolAllowlist && systemPrompt == other.systemPrompt);

  @override
  int get hashCode => Object.hash(id, name, extendsSpecId, toolAllowlist, systemPrompt);

  @override
  String toString() =>
      'YamlAgentSpec(id: $id, name: $name, extendsSpecId: $extendsSpecId)';
}
