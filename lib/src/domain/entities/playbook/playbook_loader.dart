// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#104 (R5#4 — playbook-as-spec behavior
// steering).
//
// The PlaybookLoader — document -> typed playbook with actionable
// diagnostics (FR-002). The document is the source of truth: YAML text or
// the equivalent JSON map, with every known key strictly validated and
// unknown top-level keys ignored (forward compatibility: a newer playbook
// document must not crash an older engine). The value-object constructor
// (playbook.dart) is the single source of truth for aggregate invariants;
// this loader owns the DOCUMENT-shape contract: section types, key types,
// and the mode vocabulary, each rejected with `ArgumentError.value`
// naming the offending key (house pattern: SteeringMessage.fromJson,
// SteeringQueue.fromJson).
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
  /// Parses [source] as a YAML playbook document.
  ///
  /// The top level MUST be a mapping; anything else (a list, a scalar) is
  /// rejected naming the document itself. YAML *syntax* errors propagate
  /// from the yaml package as its own exception — this loader's contract is
  /// document *shape*, not syntax.
  Playbook loadYaml(String source) {
    final dynamic document = yaml.loadYaml(source);
    if (document is! Map) {
      throw ArgumentError.value(document, 'document',
          'a playbook document must be a mapping at the top level');
    }
    return loadJson(Map<String, dynamic>.from(document));
  }

  /// Builds a [Playbook] from its JSON-map shape (the same shape
  /// `loadYaml` parses): `{id, name, description, domain?, country?,
  /// steering?, toolGating?, response?}`.
  ///
  /// Every known key is type-checked; unknown top-level keys are ignored.
  /// Throws [ArgumentError] naming the offending key — never fabricates a
  /// default for a malformed value.
  Playbook loadJson(Map<String, dynamic> json) {
    final identity = _identity(json);
    final steering = _steering(json['steering']);
    final gate = _gate(json['toolGating']);
    final response = _response(json['response']);

    // The aggregate constructor re-validates every invariant (blank-free
    // lists, mode/list consistency, positive caps) — one source of truth.
    return Playbook(
      id: identity.id,
      name: identity.name,
      description: identity.description,
      domain: identity.domain,
      country: identity.country,
      steering: steering,
      toolGate: gate,
      response: response,
    );
  }

  ({String id, String name, String description, String? domain, String? country})
      _identity(Map<String, dynamic> json) {
    String requireString(String key) {
      final value = json[key];
      if (value is! String) {
        throw ArgumentError.value(
            value, key, 'playbook.$key must be a non-empty string');
      }
      if (value.isEmpty) {
        throw ArgumentError.value(
            value, key, 'playbook.$key must be a non-empty string');
      }
      return value;
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) {
        throw ArgumentError.value(
            value, key, 'playbook.$key must be a string when present');
      }
      return value;
    }

    return (
      id: requireString('id'),
      name: requireString('name'),
      description: requireString('description'),
      domain: optionalString('domain'),
      country: optionalString('country'),
    );
  }

  List<PlaybookSteering> _steering(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw ArgumentError.value(
          raw, 'steering', 'playbook.steering must be a list of entries');
    }
    final entries = <PlaybookSteering>[];
    for (final entry in raw) {
      if (entry is! Map) {
        throw ArgumentError.value(
            entry, 'steering', 'playbook.steering entries must be mappings');
      }
      final content = entry['content'];
      if (content is! String || content.isEmpty) {
        throw ArgumentError.value(content, 'content',
            'playbook.steering entries must carry non-empty content');
      }
      final entryId = entry['id'];
      if (entryId != null && entryId is! String) {
        throw ArgumentError.value(
            entryId, 'id', 'steering entry id must be a string when present');
      }
      entries.add(PlaybookSteering(id: entryId as String?, content: content));
    }
    return entries;
  }

  PlaybookToolGate _gate(Object? raw) {
    if (raw == null) return const PlaybookToolGate(mode: PlaybookGateMode.off);
    if (raw is! Map) {
      throw ArgumentError.value(
          raw, 'toolGating', 'playbook.toolGating must be a mapping');
    }
    final modeRaw = raw['mode'];
    if (modeRaw != null && modeRaw is! String) {
      throw ArgumentError.value(
          modeRaw, 'mode', 'toolGating.mode must be a string');
    }
    final PlaybookGateMode mode;
    switch (modeRaw as String?) {
      case null:
      case 'off':
        mode = PlaybookGateMode.off;
      case 'allowlist':
        mode = PlaybookGateMode.allowlist;
      case 'blocklist':
        mode = PlaybookGateMode.blocklist;
      default:
        throw ArgumentError.value(modeRaw, 'mode',
            'toolGating.mode must be one of: off, allowlist, blocklist');
    }
    return PlaybookToolGate(
      mode: mode,
      allowed: _toolList(raw['allowed'], 'allowed'),
      blocked: _toolList(raw['blocked'], 'blocked'),
    );
  }

  List<String> _toolList(Object? raw, String key) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw ArgumentError.value(
          raw, key, 'toolGating.$key must be a list of tool names');
    }
    final tools = <String>[];
    for (final tool in raw) {
      if (tool is! String) {
        throw ArgumentError.value(
            tool, key, 'toolGating.$key entries must be strings');
      }
      if (tool.isEmpty) {
        throw ArgumentError.value(
            tool, key, 'toolGating.$key must not contain blank tool ids');
      }
      tools.add(tool);
    }
    return tools;
  }

  PlaybookResponse _response(Object? raw) {
    if (raw == null) return const PlaybookResponse();
    if (raw is! Map) {
      throw ArgumentError.value(
          raw, 'response', 'playbook.response must be a mapping');
    }
    final language = raw['language'];
    if (language != null && (language is! String || language.isEmpty)) {
      throw ArgumentError.value(language, 'language',
          'response.language must be a non-empty string when present');
    }
    final maxChars = raw['maxChars'];
    if (maxChars != null && (maxChars is! int || maxChars < 1)) {
      throw ArgumentError.value(
          maxChars, 'maxChars', 'response.maxChars must be a positive integer');
    }
    return PlaybookResponse(
      language: language as String?,
      maxChars: maxChars as int?,
    );
  }
}
