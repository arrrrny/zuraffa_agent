// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#104 (R5#4 — playbook-as-spec behavior
// steering).
//
// The Playbook value object — the playbook-as-spec schema from issue #104's
// proposed scope: "Define the playbook-as-spec schema (steering messages,
// tool gating, response constraints)". A playbook is a declarative,
// spec-shaped document (spec 005 US3: "ZikZak per-country playbooks become
// instances of agent specs — one mechanism, two uses") that the engine loads
// and applies as the active steering/behavior context — no code change per
// playbook (FR-006).
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner — the documented constitution IX
// exemption precedent: SteeringMessage (spec 081), SubAgentSpec (036),
// MissionRunner (069), SubAgentDispatchService (070), AgentSession (PR #50),
// ToolResult (PR #49), StopPolicy (PR #47).
//
// Validation: the aggregate constructor is the single source of truth for
// value invariants (spec 104 FR-001/FR-002) — identity fields non-blank,
// steering entries non-blank, gate lists blank-free and mode-consistent,
// response constraints positive. Sub-values are pure const data; the
// constructor validates the whole aggregate and throws ArgumentError.value
// naming the offending field (house pattern: SteeringMessage.fromJson,
// SubAgentSpec's constructor).

/// Element-wise string-list equality (private helper for the value
/// objects in this file — same pattern as SteeringQueue's `_listEq`).
bool _listEq(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Gate mode of a playbook's tool-gating section (FR-001).
///
/// [off] gates nothing — every tool call delegates. [allowlist] admits only
/// the tools in `allowed` (an empty `allowed` list locks down every tool).
/// [blocklist] refuses exactly the tools in `blocked`.
enum PlaybookGateMode { off, allowlist, blocklist }

/// One steering entry of a playbook (FR-001): the text the engine injects
/// as a [SteeringMessage] when the playbook is applied. Ordered narrative,
/// not a set — duplicates are preserved verbatim (spec edge case).
class PlaybookSteering {
  /// Optional entry id. When present it becomes the injected steering
  /// message's id; otherwise the runtime derives one
  /// (`pb-<playbookId>-steer-<index>`).
  final String? id;

  /// The steering text. Required non-empty (validated by the aggregate).
  final String content;

  const PlaybookSteering({this.id, required this.content});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybookSteering &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content);

  @override
  int get hashCode => Object.hash(id, content);

  @override
  String toString() =>
      'PlaybookSteering(id: $id, content: ${content.length > 40 ? '${content.substring(0, 40)}…' : content})';
}

/// The tool-gating section of a playbook (FR-001 / FR-004).
///
/// Pure data — mode/list consistency and blank-free lists are invariants
/// the aggregate [Playbook] constructor enforces: an `allowlist` gate
/// carries (possibly empty) `allowed` and an EMPTY `blocked`; a
/// `blocklist` gate carries (possibly empty) `blocked` and an EMPTY
/// `allowed`; an `off` gate carries both lists empty. A non-empty
/// irrelevant list is loader drift and is rejected.
class PlaybookToolGate {
  final PlaybookGateMode mode;
  final List<String> allowed;
  final List<String> blocked;

  const PlaybookToolGate({
    this.mode = PlaybookGateMode.off,
    this.allowed = const [],
    this.blocked = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybookToolGate &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          _listEq(allowed, other.allowed) &&
          _listEq(blocked, other.blocked));

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(allowed), Object.hashAll(blocked));

  @override
  String toString() =>
      'PlaybookToolGate(mode: ${mode.name}, allowed: ${allowed.length}, blocked: ${blocked.length})';
}

/// The response-constraint section of a playbook (FR-001 / FR-005).
///
/// [language] becomes a playbook-attributable steering directive; [maxChars]
/// mechanically caps the final response (first `maxChars` characters plus a
/// truncation marker naming the playbook).
class PlaybookResponse {
  /// Response language directive (e.g. `'de'`). Null = no directive.
  final String? language;

  /// Maximum characters of the final response. Null = unconstrained.
  final int? maxChars;

  const PlaybookResponse({this.language, this.maxChars});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybookResponse &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          maxChars == other.maxChars);

  @override
  int get hashCode => Object.hash(language, maxChars);

  @override
  String toString() => 'PlaybookResponse(language: $language, maxChars: $maxChars)';
}

/// The playbook-as-spec value object (FR-001).
///
/// A declarative, spec-shaped document: identity ([id], [name],
/// [description], optional [domain]/[country] metadata) plus the three
/// behavior sections the engine applies at runtime — [steering] (messages
/// injected through the SteeringQueue), [toolGate] (wraps the mission's
/// ToolDispatcher), and [response] (language directive + mechanical length
/// cap). Loaded from YAML/JSON by `PlaybookLoader`; applied by
/// `PlaybookRuntime`. Adding a playbook requires only a new document —
/// no engine file branches on playbook identity or content (FR-006).
class Playbook {
  /// Unique playbook id (e.g. `'pb-de-001'`). Attributed into steering
  /// message ids and the response truncation marker so observers can trace
  /// behavior back to the loaded document.
  final String id;

  /// Short playbook name (e.g. `'germany'`).
  final String name;

  /// Human-readable description of what the playbook steers.
  final String description;

  /// Optional domain tag (e.g. `'country'`) — a playbook is domain-agnostic
  /// by design; this is preserved metadata, not a behavioral switch.
  final String? domain;

  /// Optional country code (e.g. `'DE'`) for country playbooks. Preserved
  /// metadata, not a behavioral switch.
  final String? country;

  /// Ordered steering entries, document order preserved (duplicates
  /// included). Defensively copied into an unmodifiable view.
  final List<PlaybookSteering> steering;

  /// The tool gate. Defaults to `off` (no gating).
  final PlaybookToolGate toolGate;

  /// The response constraints. Defaults to none.
  final PlaybookResponse response;

  Playbook({
    required this.id,
    required this.name,
    required this.description,
    this.domain,
    this.country,
    List<PlaybookSteering> steering = const [],
    this.toolGate = const PlaybookToolGate(mode: PlaybookGateMode.off),
    this.response = const PlaybookResponse(),
  }) : steering = List.unmodifiable(steering) {
    // Construction-time validation (FR-001/FR-002): identity fields are
    // required non-empty; optional metadata is non-empty when present.
    // Invalid playbooks fail fast at construction/load time instead of
    // misbehaving at dispatch time (SubAgentSpec precedent, spec 036).
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Playbook.id must not be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Playbook.name must not be empty');
    }
    if (description.isEmpty) {
      throw ArgumentError.value(
          description, 'description', 'Playbook.description must not be empty');
    }
    if (domain != null && domain!.isEmpty) {
      throw ArgumentError.value(
          domain, 'domain', 'Playbook.domain must be non-empty when present');
    }
    if (country != null && country!.isEmpty) {
      throw ArgumentError.value(
          country, 'country', 'Playbook.country must be non-empty when present');
    }
    // Steering entries carry the text the engine will inject — a blank
    // entry would fabricate an empty steering message at mission start.
    for (final entry in this.steering) {
      if (entry.content.isEmpty) {
        throw ArgumentError.value(entry.content, 'content',
            'Playbook.steering entries must have non-empty content');
      }
    }
    // Gate invariants (FR-002): blank-free lists, and each mode carries
    // exactly the lists that apply to it — a non-empty irrelevant list is
    // loader drift that would silently widen or corrupt gating (same
    // rationale as spec 036 FR-002's blank-id rule). Empty lists are
    // inert and always legal: an empty `allowed` locks down every tool,
    // an empty `blocked` refuses nothing.
    final gate = toolGate;
    if (gate.allowed.any((t) => t.isEmpty)) {
      throw ArgumentError.value(gate.allowed, 'allowed',
          'PlaybookToolGate.allowed must not contain blank tool ids');
    }
    if (gate.blocked.any((t) => t.isEmpty)) {
      throw ArgumentError.value(gate.blocked, 'blocked',
          'PlaybookToolGate.blocked must not contain blank tool ids');
    }
    switch (gate.mode) {
      case PlaybookGateMode.off:
        if (gate.allowed.isNotEmpty) {
          throw ArgumentError.value(gate.allowed, 'allowed',
              'an off gate carries no allowed list — remove it or set mode');
        }
        if (gate.blocked.isNotEmpty) {
          throw ArgumentError.value(gate.blocked, 'blocked',
              'an off gate carries no blocked list — remove it or set mode');
        }
      case PlaybookGateMode.allowlist:
        if (gate.blocked.isNotEmpty) {
          throw ArgumentError.value(gate.blocked, 'blocked',
              'a blocklist has no effect on an allowlist gate — remove it');
        }
      case PlaybookGateMode.blocklist:
        if (gate.allowed.isNotEmpty) {
          throw ArgumentError.value(gate.allowed, 'allowed',
              'an allowlist has no effect on a blocklist gate — remove it');
        }
    }
    // Response invariants (FR-002): the cap, when set, is a positive int;
    // the language directive, when set, is non-empty.
    final response = this.response;
    if (response.maxChars != null && response.maxChars! < 1) {
      throw ArgumentError.value(response.maxChars, 'maxChars',
          'PlaybookResponse.maxChars must be >= 1 when set');
    }
    if (response.language != null && response.language!.isEmpty) {
      throw ArgumentError.value(response.language, 'language',
          'PlaybookResponse.language must be non-empty when set');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playbook &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          domain == other.domain &&
          country == other.country &&
          _steeringEq(steering, other.steering) &&
          toolGate == other.toolGate &&
          response == other.response);

  static bool _steeringEq(List<PlaybookSteering> a, List<PlaybookSteering> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        domain,
        country,
        Object.hashAll(steering),
        toolGate,
        response,
      );

  @override
  String toString() =>
      'Playbook(id: $id, name: $name, domain: $domain, country: $country, '
      'steering: ${steering.length}, toolGate: $toolGate, response: $response)';
}
