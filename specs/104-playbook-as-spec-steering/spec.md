# Feature Specification: Playbook-as-spec behavior steering (R5#4)

**Branch**: `104-playbook-as-spec-steering` (off master `9d0b341`) | **Date**: 2026-08-29

**Input**: GitHub issue #104 — "feat: country playbook loaded as a spec changes
agent behavior without code change (R5#4)". Epic: R5 — sub-agents & specs
(issue #6). Parent acceptance criterion: R5#4 (playbook-as-spec changes behavior
without code change).

## Summary

A country playbook (or any domain playbook) is a **declarative, spec-shaped
document**. When loaded, the engine applies it as the **active steering and
behavior context** — the agent reconfigures its steering messages, its tool
gating, and its response constraints **purely from the loaded document**.
Today every agent-behavior change requires code: there is no first-class way
to load a declarative playbook that the engine reads and applies as behavioral
steering (`grep -ri playbook test/` returns nothing — the capability is
unimplemented and untested).

This is the strategic "specs-as-data" pattern from spec 005 US3 (issue #6):
"ZikZak per-country playbooks (zik_zak architecture §9) become instances of
agent specs — one mechanism, two uses", and its acceptance scenario 3: "Given a
country playbook YAML, When loaded as a spec, Then agent behavior changes with
no code change."

This spec:

1. **Defines the playbook-as-spec schema** — a declarative document with three
   behavior sections: steering messages, tool gating, and response constraints.
2. **Adds the engine path that reads a loaded playbook** and applies it as the
   active steering/behavior context: playbook steering entries become steering
   messages injected through the existing `SteeringQueue` (observable as
   `SteeringInjected` events), playbook tool gating wraps the existing
   `ToolDispatcher` (refusals are typed failures), and playbook response
   constraints shape the final response (a language directive emitted as
   steering plus a mechanical length constraint).
3. **Guarantees zero-code-change extensibility**: adding a new playbook
   requires only a new document — no new code paths. The acceptance test
   loads two different country playbooks (and a third, novel one) through the
   identical engine code and observes different behavior from each.

**Out of scope** (from issue #104): authoring UI for playbooks; remote
playbook fetching / hot-reload (can follow later).

## User scenarios

### US1 — A playbook document loads as a typed spec (P1)

As an operator, I write a declarative playbook (YAML or the equivalent JSON
map) with an identity (`id`, `name`, `description`) and three behavior
sections — `steering` (an ordered list of message entries), `toolGating`
(mode + tool lists), and `response` (constraints) — and the engine loads it
into a typed playbook value object. A malformed playbook is rejected at load
time with actionable diagnostics naming the offending field — never a silent
default.

**Why this priority**: the schema is the contract everything else applies;
without a loadable, validated document there is nothing to steer with.

**Independent test**: a valid YAML document round-trips into the typed value
object with every field preserved; each malformed variant (missing identity,
blank steering content, unknown gating mode, non-positive `maxChars`,
inconsistent gating lists) is rejected with a diagnostic naming the field.

**Acceptance scenarios**:

1. **Given** a valid playbook document, **When** loaded, **Then** the engine
   holds a typed playbook whose identity, steering entries, tool gate, and
   response constraints match the document exactly.
2. **Given** a malformed playbook document (missing `id`, blank steering
   `content`, gating mode that is not one of `off` / `allowlist` /
   `blocklist`, `maxChars` less than 1, a non-empty irrelevant gate list —
   `blocked` on an `allowlist` gate, `allowed` on a `blocklist` gate, or
   either on an `off` gate), **When** loaded, **Then** loading fails with a
   diagnostic that names the offending field and the document is never
   partially applied.

### US2 — A loaded playbook reconfigures the agent's steering (P1)

As the engine, when a playbook is loaded I apply its steering section as the
active steering context: each steering entry becomes a `SteeringMessage`
injected at mission start through the existing `SteeringQueue`, so the
mission transcript and the `SteeringInjected` event stream show the playbook's
steering content — with no code change.

**Why this priority**: steering is the primary R5 behavior lever (the issue
title says "changes agent behavior… steering"); it must flow through the
engine's existing steering surfaces, not a new parallel path.

**Independent test**: a mission started with a loaded playbook emits one
`SteeringInjected` event per playbook steering entry (in document order) and
the transcript contains each entry's content as a user-role message.

**Acceptance scenarios**:

1. **Given** a loaded playbook with steering entries `[s1, s2]`, **When** a
   mission starts, **Then** the steering queue is seeded FIFO with `s1`, `s2`
   and the engine drains both — two `SteeringInjected` events, in order.
2. **Given** a playbook with an empty steering section, **When** a mission
   starts, **Then** no playbook steering is injected (behavior identical to
   no playbook on this surface).

### US3 — A loaded playbook reconfigures the agent's tool gating (P1)

As the engine, when a playbook is loaded I apply its tool-gating section to
tool dispatch: the playbook's gate wraps the mission's `ToolDispatcher` —
`allowlist` mode refuses every tool not on the list, `blocklist` mode refuses
every tool on it, `off` (or an absent section) gates nothing. A refusal is a
typed failure result (`tool not allowed: <name>`) so the mission records the
refused call and continues — the same contract as the existing sub-agent
allowlist dispatcher.

**Why this priority**: tool gating is the second named observable in the
issue's acceptance ("steering emitted, tool gating applied"); it must reuse
the established typed-refusal contract.

**Independent test**: with an `allowlist` playbook gate, a call to an
unlisted tool fails with `tool not allowed: <name>` and the inner dispatcher
never sees it; an allowlisted call delegates with arguments preserved.

**Acceptance scenarios**:

1. **Given** a playbook gate of mode `allowlist` with `allowed: [search,
   fetch]`, **When** the agent dispatches `shell`, **Then** dispatch fails
   with `tool not allowed: shell` and the wrapped dispatcher is never invoked.
2. **Given** a playbook gate of mode `blocklist` with `blocked: [shell]`,
   **When** the agent dispatches `search`, **Then** dispatch delegates to the
   wrapped dispatcher; dispatching `shell` fails with
   `tool not allowed: shell`.
3. **Given** a playbook with gate mode `off` (or no tool-gating section),
   **When** any tool is dispatched, **Then** the call delegates unchanged —
   the playbook adds no gate.

### US4 — A loaded playbook constrains the agent's response shape (P2)

As the engine, when a playbook is loaded I apply its response section: a
`language` constraint is emitted as a playbook steering directive (the
response-shape instruction reaches the model through steering), and a
`maxChars` constraint mechanically caps the final response — the first
`maxChars` characters are preserved, followed by a truncation marker naming
the playbook.

**Why this priority**: response shape is the third named behavior surface in
the issue ("steering, tool gating, and response shape"); it composes on US2's
steering channel plus one mechanical transform.

**Independent test**: a playbook with `response: {language: de, maxChars:
120}` injects the language directive as steering, and a 500-character final
response is truncated to its first 120 characters plus a marker naming the
playbook id.

**Acceptance scenarios**:

1. **Given** a loaded playbook with `response.language: de`, **When** the
   mission starts, **Then** a steering message carrying the language
   directive (attributable to the playbook) is injected with the other
   playbook steering.
2. **Given** a loaded playbook with `response.maxChars: 120`, **When** the
   final response is longer than 120 characters, **Then** the constrained
   response is exactly the first 120 characters followed by a truncation
   marker naming the playbook; a response at or under 120 characters passes
   through unchanged.

### US5 — A different playbook changes behavior with zero code change (P1 — the R5#4 acceptance)

As the R5 acceptance proof, the same engine code — the same loader, the same
steering seeding, the same tool gate, the same response constraint — is
driven by two different country playbook documents (Germany and Japan) and a
third novel document, and produces observably different behavior for each:
different steering content emitted, different tools refused, different
response constraints applied. No engine file differs between the runs; only
the loaded document does.

**Why this priority**: this IS the acceptance criterion (R5#4: "a playbook
loaded as a spec changes agent behavior without code change"); US1–US4 build
its pieces, US5 proves the property end to end.

**Independent test**: one acceptance test loads three playbooks through the
identical code path and asserts the observable behavior differs per document
and matches each document's declarations.

**Acceptance scenarios**:

1. **Given** the Germany playbook, **When** a mission runs, **Then** its
   steering is emitted, its gated tools are refused, and its response
   constraints hold — as declared by that document.
2. **Given** the Japan playbook (same engine code), **When** a mission runs,
   **Then** the behavior follows the Japan document instead — different
   steering content, different tool refusals, different constraints.
3. **Given** a third, previously unseen playbook document, **When** loaded
   and run through the same code, **Then** it also steers/gates/constrains
   per its own declarations — adding a playbook required only the document.

### Edge cases

- A playbook with all three behavior sections empty/absent loads and applies
  as a no-op (behavior identical to no playbook — no steering injected, no
  gate installed, no response constraint).
- A `toolGating` section of mode `allowlist` with an empty `allowed` list is
  valid and refuses every tool (lock-down); mode `blocklist` with an empty
  `blocked` list refuses nothing.
- Blank tool ids in a gate list are rejected at load (loader drift would
  silently widen or corrupt gating).
- Duplicate tool names within one gate list are tolerated (a set semantics —
  the gate checks membership) but duplicates in steering entries are
  preserved verbatim (steering is an ordered narrative, not a set).
- YAML that is not a mapping at the top level (a list or a scalar) is
  rejected with a diagnostic.
- The playbook never mutates shared engine state: seeding returns new queue
  snapshots (the queue is a value object), and the gate wraps — never
  replaces — the mission's dispatcher.

## Requirements

### Functional requirements

- **FR-001**: The playbook-as-spec schema MUST comprise identity fields
  (`id`, `name`, `description` — all required, non-empty) and three behavior
  sections: `steering` (ordered list of entries, each with required
  non-empty `content` and optional `id`), `toolGating` (a `mode` of
  `off` | `allowlist` | `blocklist` plus an `allowed` list and a `blocked`
  list), and `response` (optional `language` string, optional `maxChars`
  int). Optional metadata (`domain`, `country`) MAY be present and is
  preserved.
- **FR-002**: The engine MUST load a playbook document (YAML source or the
  equivalent JSON map) into the typed playbook value object, preserving
  every field. Malformed documents MUST be rejected at load time with typed
  errors (`ArgumentError` naming the offending key) covering at least:
  missing/blank identity fields; a top-level structure that is not a
  mapping; a `steering` entry with missing/blank `content`; a
  `toolGating.mode` outside the three legal values; a mode/list
  inconsistency (a non-empty `blocked` list on an `allowlist` gate, a
  non-empty `allowed` list on a `blocklist` gate, or non-empty lists on an
  `off` gate — empty lists are inert and always legal); blank tool ids in a
  gate list; a `response.maxChars`
  that is not a positive integer; a `response.language` that is not a
  non-empty string.
- **FR-003**: The engine MUST apply a loaded playbook's steering section as
  the active steering context: each steering entry becomes a
  `SteeringMessage` (deterministic, playbook-attributable message ids)
  seeded FIFO into the mission's `SteeringQueue` at mission start, drained
  by the existing engine loop, observable as one `SteeringInjected` event
  per entry in document order.
- **FR-004**: The engine MUST apply a loaded playbook's tool-gating section
  by wrapping the mission's `ToolDispatcher`: `allowlist` mode refuses
  (typed failure `tool not allowed: <name>`, inner dispatcher never
  invoked) every tool not in `allowed`; `blocklist` mode refuses every tool
  in `blocked`; `off`/absent delegates everything unchanged.
- **FR-005**: The engine MUST apply a loaded playbook's response section: a
  `language` constraint is rendered as one playbook-attributable steering
  directive injected with the playbook steering; a `maxChars` constraint
  caps the final response — exactly the first `maxChars` characters
  preserved, followed by a truncation marker naming the playbook id
  (responses at or under `maxChars` pass through unchanged).
- **FR-006**: Adding a new playbook MUST require no code change — only a
  new document. The loader, steering seeding, tool gate, and response
  constraint are document-driven; no engine surface may branch on a
  specific playbook's identity or content.
- **FR-007**: The playbook application MUST compose with the existing
  engine surfaces only — `SteeringQueue`/`SteeringMessage` (spec 033),
  `ToolDispatcher` (spec 003/047), the engine loop's steering drain (spec
  002/069) — and MUST NOT mutate shared state: steering seeding returns new
  queue snapshots; the gate wraps the dispatcher it is given.
- **FR-008** (gates): `dart analyze --fatal-infos` exit 0 on the changed
  files; full `dart test` green (baseline 1163 passed + new); the runtime
  purity gate holds (no `dart:io` imports in the new files; constitution
  VII).

### Key entities

- **Playbook** — the playbook-as-spec value object: identity, steering
  entries, tool gate, response constraints; value equality across all
  fields. Plain Dart value object (constitution IX exemption — the
  documented house precedent: `SteeringMessage` (spec 081), `SubAgentSpec`
  (036), `MissionRunner` (069), `SubAgentDispatchService` (070); compiles
  without build_runner).
- **PlaybookLoader** — document → `Playbook`: YAML/JSON parsing with the
  typed error contract of FR-002.
- **PlaybookRuntime** — the engine application: seeds the steering queue
  from a loaded playbook, wraps a dispatcher with the playbook's tool
  gate, applies the response constraints to a final response. Injectable
  clock for deterministic timestamps (house pattern, spec 069).

## Success criteria

- **SC-001** (US1 / FR-001, FR-002): a valid playbook document loads with
  every field preserved; every malformed variant is rejected with a typed
  diagnostic naming the offending field.
- **SC-002** (US2 / FR-003): a mission under a loaded playbook emits one
  `SteeringInjected` event per steering entry in document order; an empty
  steering section injects nothing.
- **SC-003** (US3 / FR-004): under an `allowlist` gate an unlisted tool
  fails with `tool not allowed: <name>` and the inner dispatcher is never
  invoked; under a `blocklist` gate only listed tools are refused; `off`
  delegates everything.
- **SC-004** (US4 / FR-005): a `language` constraint is injected as a
  playbook-attributable steering directive; a `maxChars` constraint
  truncates over-long responses to the first `maxChars` characters plus a
  marker naming the playbook; short responses pass through.
- **SC-005** (US5 / FR-006 — the R5#4 acceptance): three different playbook
  documents driven through the identical engine code produce document-
  specific observable behavior (steering emitted, tool gating applied,
  response constrained) with zero code change between runs.
- **SC-006** (FR-008): `dart analyze --fatal-infos` clean on the changed
  files; full `dart test` green; purity gate holds.

## Assumptions

- Playbook documents are local declarative documents (YAML string or JSON
  map) handed to the loader; remote fetching and hot-reload are explicitly
  out of scope (issue #104) and the loading side integrates later with
  raptorr's `playbook_get` (arrrrny/raptorr#126, spec 005's assumption).
- A playbook steers a mission through the surfaces the engine already has
  (steering queue, tool dispatcher, final response); it does not introduce
  a new engine loop, event type, or persistence format.
- The mechanical `maxChars` constraint applies to the final response text
  (mission summary / final assistant content); token-level budgeting is a
  budget-profile concern (spec 005 US1), out of scope here.

## Dependencies

- Builds on: master `9d0b341` — `SteeringMessage` + `SteeringQueue`
  (spec 033 / PR #103 for spec 081), `MissionRunner` steering drain (spec
  069), `ToolDispatcher` + `AllowlistToolDispatcher` typed-refusal contract
  (spec 070), `YamlAgentSpec.validate` diagnostics precedent (spec 005
  A6 / 036).
- Independent of: every other spec in flight — new files only
  (`lib/src/domain/entities/playbook/`, `lib/src/engine/playbook_runtime.dart`,
  mirrored tests); no existing source file changes.
- Related but out of scope: `YamlAgentSpec` inheritance resolution (spec
  005 US3 scenarios 1–2 — `extends` is the agent-spec mechanism, not the
  playbook mechanism), sub-agent dispatch budgets (spec 070), playbook
  serving (`raptorr.playbook_get`), authoring UI, hot-reload (issue #104
  out-of-scope list).
