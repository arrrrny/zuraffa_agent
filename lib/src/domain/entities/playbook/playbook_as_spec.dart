// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5.3 — "ZikZak playbooks … become an
// instance of agent specs — one mechanism, two uses") and spec 005 US3
// acceptance scenario 7 / SC-004: "Given a country playbook YAML, When
// loaded as a spec, Then agent behavior changes with no code change."
//
// The resolution of a loaded [Playbook] INTO the existing declarative
// agent-spec machinery: the document becomes a first-class [SubAgentSpec]
// (spec 036) — the same spec surface the dispatch runtime (spec 070)
// consumes for named agent types, tool allowlists, budgets, and risk tiers.
// One mechanism, two uses: the SAME document steers a mission through
// PlaybookRuntime (spec 104) AND instantiates spec-driven sub-agents here —
// adding a country playbook still requires only the document (FR-006, no
// code change per playbook).
//
// Resolution contract (total and documented — a playbook either resolves or
// throws an actionable diagnostic naming the offending document part):
//
// - `name`        <- [Playbook.id], the document's stable unique key — the
//   spec name is the registry key `extends` references (spec 036), and two
//   revisions of the same country strategy must not collide.
// - `description` <- [Playbook.description].
// - `systemPrompt`<- the steering entries joined with newlines in document
//   order; when the playbook declares [PlaybookResponse.language], the
//   pinned PlaybookRuntime directive ("[playbook:<id>] Respond in language
//   '<language>'.") is appended — the SAME text both surfaces apply, so one
//   document behaves identically as playbook steering and as a spec system
//   prompt (pinned by playbook_as_spec_test U5). A playbook carrying
//   neither steering nor a language directive is REJECTED: it has nothing
//   to resolve into a system prompt (the spec 036 FR-001 non-empty
//   invariant, surfaced as an actionable load-time diagnostic).
// - `tools`       <- the tool gate, read as the spec's tool ALLOWLIST —
//   specs are allowlist-native (spec 070's AllowlistToolDispatcher): an
//   allowlist gate resolves to `allowed`; an off (or absent) gate resolves
//   to an EMPTY allowlist (the spec grants no tools — declare an explicit
//   allowlist to grant them); a blocklist gate is REJECTED — a refusal list
//   has no allowlist semantics without the tool universe, and silently
//   complementing it would widen access. Restate the gate as an allowlist.
//   Deliberate asymmetry with PlaybookRuntime: an `off` gate there refuses
//   NOTHING (all tools pass); here it yields NO tools — a spec has no
//   allow-all representation, so this side fails closed.
// - `riskTier`    <- [RiskTier.safe] (the playbook schema carries no risk
//   tier; the safe default, spec 036).
// - budgets       <- none (null — inherit from the parent spec per spec
//   036's null-means-inherit contract; the playbook schema has no budgets).
// - `extendsSpec` <- null (root instance); `subAgents` <- [] (leaf).
// - dropped       <- [Playbook.name], [Playbook.domain], [Playbook.country]
//   (metadata the spec shape has no fields for — the spec `name` resolves
//   from [Playbook.id], not these) and [PlaybookResponse.maxChars] — the
//   character cap is enforced ONLY by PlaybookRuntime.constrainResponse
//   (spec 104 FR-005); a spec-driven sub-agent's output is uncapped unless
//   the applying surface enforces it.
//
// Pattern: plain Dart extension (no @Zorphy annotation) so the file
// compiles without running build_runner — the documented constitution IX
// exemption precedent (Playbook, SubAgentSpec, SteeringMessage).

import '../agent_tool/agent_tool.dart' show RiskTier;
import '../sub_agent_spec/sub_agent_spec.dart';
import 'playbook.dart';

/// Resolves a loaded [Playbook] as an instance of the declarative
/// agent-spec machinery (issue #6 R5.3 — one mechanism, two uses).
extension PlaybookAsSpec on Playbook {
  /// Resolves this playbook into a [SubAgentSpec] per the documented
  /// contract (see the file header). Throws [ArgumentError] with an
  /// actionable diagnostic when the document cannot resolve: a blocklist
  /// gate (no allowlist semantics) or a playbook carrying neither steering
  /// nor a response language (nothing to resolve into a system prompt).
  SubAgentSpec toSubAgentSpec() {
    // The system prompt: the steering text IS the behavior directive the
    // spec-driven agent runs under. Same lines, same order, same language
    // directive as PlaybookRuntime injects — one document, two uses.
    final directives = <String>[for (final entry in steering) entry.content];
    final language = response.language;
    if (language != null) {
      directives.add("[playbook:$id] Respond in language '$language'.");
    }
    if (directives.isEmpty) {
      throw ArgumentError.value(
        this,
        'steering',
        "playbook '$id' carries no steering and no response language — "
            'nothing to resolve into a spec system prompt',
      );
    }

    // The tools: the gate read as the spec's allowlist (allowlist-native).
    final List<String> tools;
    switch (toolGate.mode) {
      case PlaybookGateMode.allowlist:
        tools = List.of(toolGate.allowed);
      case PlaybookGateMode.off:
        tools = const [];
      case PlaybookGateMode.blocklist:
        throw ArgumentError.value(
          toolGate,
          'toolGating',
          "playbook '$id' gates with a blocklist — a refusal list has "
              'no allowlist semantics for a spec; restate the gate as '
              'an allowlist',
        );
    }

    return SubAgentSpec(
      name: id,
      description: description,
      systemPrompt: directives.join('\n'),
      tools: tools,
      subAgents: const [],
      riskTier: RiskTier.safe,
    );
  }
}
