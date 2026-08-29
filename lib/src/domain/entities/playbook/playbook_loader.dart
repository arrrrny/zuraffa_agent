// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#104 (R5#4 — playbook-as-spec behavior
// steering).
//
// The PlaybookLoader — document -> typed playbook (FR-002).
//
// MINIMAL STATE (cycle 4 green): only what U10/U11/U16 demand — parse the
// YAML mapping, read the known keys, default absent sections. Document-shape
// diagnostics (the FR-002 typed-error matrix) are deliberately NOT here yet:
// they arrive with their own reds (U12–U17) per the TDD discipline — the
// speculative validation that landed in cycle 4's commit was reverted
// (Hard Rule 2: no implementation before its failing test).
//
// Pattern: plain Dart, no @Zorphy annotation (constitution IX exemption —
// same documented precedent as the Playbook value object).

import 'package:yaml/yaml.dart' as yaml;

import 'playbook.dart';

/// Loads a playbook document into a typed [Playbook] (FR-002).
///
/// A playbook is data, not code: adding a new playbook means adding a new
/// document — this loader (and the engine surfaces downstream of it) never
/// branches on a specific playbook's identity or content (FR-006).
class PlaybookLoader {
  /// Parses [source] as a YAML playbook document (top level: a mapping).
  Playbook loadYaml(String source) {
    final dynamic document = yaml.loadYaml(source);
    return loadJson(Map<String, dynamic>.from(document as Map));
  }

  /// Builds a [Playbook] from its JSON-map shape: `{id, name, description,
  /// domain?, country?, steering?, toolGating?, response?}`. Unknown
  /// top-level keys are ignored (forward compatibility).
  Playbook loadJson(Map<String, dynamic> json) {
    final gateRaw = json['toolGating'] as Map?;
    final responseRaw = json['response'] as Map?;
    return Playbook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      domain: json['domain'] as String?,
      country: json['country'] as String?,
      steering: [
        for (final entry in (json['steering'] as List? ?? const []))
          PlaybookSteering(
            id: (entry as Map)['id'] as String?,
            content: entry['content'] as String,
          ),
      ],
      toolGate: gateRaw == null
          ? const PlaybookToolGate(mode: PlaybookGateMode.off)
          : PlaybookToolGate(
              mode: PlaybookGateMode.values
                  .byName(gateRaw['mode'] as String? ?? 'off'),
              allowed: [
                for (final tool in (gateRaw['allowed'] as List? ?? const []))
                  tool as String,
              ],
              blocked: [
                for (final tool in (gateRaw['blocked'] as List? ?? const []))
                  tool as String,
              ],
            ),
      response: PlaybookResponse(
        language: responseRaw?['language'] as String?,
        maxChars: responseRaw?['maxChars'] as int?,
      ),
    );
  }
}
