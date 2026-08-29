# Test List: Playbook-as-spec behavior steering (R5#4)

---
feature: 104-playbook-as-spec-steering
loop: outside-in # new feature: acceptance tests staged red before the runtime units that close them
profile: .specify/memory/tdd-profile.md
spec_criteria: 6 # SC-001..SC-006 in spec.md
planned_at: 9d0b341
updated_at: ff0fc90
suite_baseline: green # 1163 passed / 2 skipped at 9d0b341 (master), ~49s
---

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. Each stays red until the feature works
end to end through its real entry point.

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A valid playbook document (YAML) loads as the typed spec with every field preserved — identity, metadata, steering order (incl. duplicates verbatim), gate lists, response constraints | SC-001, US1, FR-001, FR-002 | example | DONE | `test/domain/entities/playbook/playbook_loader_test.dart::spec 104 — PlaybookLoader::loads — U10: full YAML document preserves every field` |
| A2  | Every malformed document variant is rejected at load with `ArgumentError` naming the offending key — never a generic exception, never a silent default, never partially applied | SC-001, US1, FR-002 | example | DONE | `…::rejects — the malformed-variant matrix (U12–U17)` |
| A3  | A mission under a loaded playbook emits one `SteeringInjected` event per steering entry in document order, and each entry's content appears in the transcript as a user message (through `MissionRunner.run`) | SC-002, US2, FR-003 | example | DONE | `test/engine/playbook_runtime_test.dart::spec 104 — R5#4 acceptance::A3: playbook steering drains through the mission loop` |
| A4  | The playbook's tool gate refuses/allows dispatch per its mode through a running mission: a refused tool yields `ToolCallCompleted(ok: false)` and the typed `tool not allowed: <name>` error in the transcript; an allowed tool dispatches | SC-003, US3, FR-004 | example | DONE | `…::A4: playbook tool gating refuses the blocked tool in a mission` |
| A5  | Response constraints shape the response end to end: the `language` directive is injected as playbook steering and an over-long final response is capped to its first `maxChars` characters plus the truncation marker | SC-004, US4, FR-005 | example | DONE | `…::A5: response constraints shape the mission response` |
| A6  | Three different playbook documents (Germany, Japan, and a third novel one) driven through the IDENTICAL engine code produce document-specific observable behavior — different steering emitted, different tools refused, different constraints — with zero code change between runs | SC-005, US5, FR-006 (R5#4) | example | DONE | `…::A6: three documents, one code path — behavior follows the document (R5#4)` |
| A7  | Gates: `dart analyze --fatal-infos` zero findings on the changed files; full `dart test` green (baseline 1163/2 + new); purity gate — no `dart:io` imports in the new files | SC-006, FR-008 | gate | PENDING | gates at branch HEAD (counts recorded in `tdd/verification.md`) |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them. Each line names one
observable result. Test names carry the behavior id (`U1: …`) so every red is
individually runnable with `--plain-name`.

### `lib/src/domain/entities/playbook/playbook.dart` — schema value object (FR-001)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Construction preserves every field: identity, optional `domain`/`country` metadata, steering entries in document order (duplicates verbatim), gate mode + lists, response constraints | FR-001 | example | DONE | `test/domain/entities/playbook/playbook_test.dart::spec 104 — Playbook schema::U1: construction preserves every field` |
| U2  | Value equality across all fields: two identical-constructed playbooks are `==` with agreeing `hashCode`; changing any ONE field (id, steering, gate mode, allowed list, response) breaks `==` | FR-001 | example | DONE | `…::U2: value equality spans every field` |
| U3  | Blank identity is rejected: empty/blank `id`, `name`, or `description` throws `ArgumentError` naming the field; blank-when-present `domain`/`country` likewise | FR-001, FR-002 | example | DONE | `…::U3: blank identity fields are rejected` |
| U4  | A steering entry with blank `content` throws `ArgumentError` naming `content`; a non-blank entry with optional id constructs | FR-001, FR-002 | example | DONE | `…::U4: blank steering content is rejected` |
| U5  | Blank tool ids in `allowed` or `blocked` throw `ArgumentError` naming the list | FR-002 | example | DONE | `…::U5: blank tool ids in a gate list are rejected` |
| U6  | Mode/list consistency: a non-empty irrelevant list (`blocked` on an `allowlist` gate, `allowed` on a `blocklist` gate, either on an `off` gate) throws `ArgumentError` | FR-002 | example | DONE | `…::U6: non-empty irrelevant gate lists are rejected` |
| U7  | The legal gate boundaries construct: `allowlist` with an empty `allowed` list (lock-down), `blocklist` with an empty `blocked` list (gate nothing), `off` with both lists empty | FR-001, FR-002 | example | DONE | `…::U7: legal gate boundaries construct (lock-down, empty, off)` |
| U8  | Response-constraint boundaries: `maxChars < 1` rejected with `ArgumentError` naming `maxChars`, `maxChars == 1` legal, blank `language` rejected naming `language`, both-null legal (no constraints) | FR-001, FR-002 | example | DONE | `…::U8: response constraint boundaries (maxChars 0/1, blank language)` |
| U9  | `toString()` names the type and the identity fields without dumping full steering content | FR-001 | example | DONE | `…::U9: toString names the type and identity` |

### `lib/src/domain/entities/playbook/playbook_loader.dart` — document → playbook (FR-002)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U10 | A full valid YAML document loads to a playbook equal to the hand-constructed equivalent — every field preserved including steering order, duplicates, and metadata | FR-002, FR-001 | example | DONE | `test/domain/entities/playbook/playbook_loader_test.dart::spec 104 — PlaybookLoader::U10: full YAML document preserves every field` |
| U11 | The JSON path and the YAML path agree: the equivalent JSON map loads to the equal playbook; unknown top-level keys are ignored (forward compatibility) | FR-002 | example | DONE | `…::U11: JSON path equals YAML path; unknown keys ignored` |
| U12 | Top-level shape: a non-mapping document (list, scalar) and missing/wrong-typed identity keys throw `ArgumentError` naming `id`/`name`/`description` | FR-002 | example | DONE | `…::U12: non-map top level and bad identity are rejected` |
| U13 | Steering shape: `steering` that is not a list, an entry that is not a map, and an entry with missing/blank `content` throw `ArgumentError` (the latter naming `content`) | FR-002 | example | DONE | `…::U13: malformed steering section is rejected` |
| U14 | Gate shape: an unknown `mode` string throws `ArgumentError` naming `mode`; `allowed`/`blocked` that are not string lists (or contain blanks) throw naming the list | FR-002 | example | DONE | `…::U14: malformed toolGating section is rejected` |
| U15 | Response shape: `maxChars` that is not an int or is < 1 throws naming `maxChars`; `language` that is not a non-empty string throws naming `language` | FR-002 | example | DONE | `…::U15: malformed response section is rejected` |
| U16 | An identity-only document (all sections absent) loads as the no-op playbook: no steering, `off` gate with empty lists, no response constraints | FR-001, FR-002 | example | DONE | `…::U16: identity-only document loads as the no-op playbook` |
| U17 | A document whose gate is mode/list-inconsistent (allowlist + non-empty blocked; off + non-empty lists) is rejected at load — the value-object diagnostics surface through the loader | FR-002 | example | DONE | `…::U17: inconsistent gate documents are rejected at load` |

### `lib/src/engine/playbook_runtime.dart` — the application (FR-003..FR-007)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U18 | `steeringMessages()` maps entries to `SteeringMessage`s in document order: content verbatim, `injectedAt` from the runtime's clock, default id `pb-<playbookId>-steer-<i>`, an entry's own `id` respected when present | FR-003 | example | DONE | `test/engine/playbook_runtime_test.dart::spec 104 — PlaybookRuntime steering::U18: entries become steering messages in document order` |
| U19 | With `response.language` set, exactly one directive message is appended after the entries: content `[playbook:<id>] Respond in language '<language>'.`, id `pb-<playbookId>-lang` | FR-005 | example | DONE | `…::U19: language constraint appends the pinned directive message` |
| U20 | With no steering entries and no language constraint, `steeringMessages()` is empty | FR-003 | example | DONE | `…::U20: empty steering yields no messages` |
| U21 | `seedSteering(queue)` returns a NEW queue with the playbook messages enqueued FIFO (document order preserved head→tail); the input queue is unmutated; `processedCount` is preserved | FR-003, FR-007 | example | DONE | `…::U21: seedSteering returns a new FIFO-seeded queue` |
| U22 | Seeding a playbook with no messages returns a queue equal to the input (no-op) | FR-003, FR-007 | example | DONE | `…::U22: seeding nothing is a no-op` |
| U23 | A gate of mode `off` delegates every call unchanged — `toolName`, `arguments`, and `isInternalMission` all reach the inner dispatcher | FR-004 | example | DONE | `…::spec 104 — PlaybookRuntime tool gate::U23: off gate delegates everything` |
| U24 | An `allowlist` gate refuses an unlisted tool: `success: false`, `result: ''`, `error: 'tool not allowed: <name>'`, no artifact refs, and the inner dispatcher is never invoked; a listed tool delegates with arguments preserved | FR-004 | example | DONE | `…::U24: allowlist gate refuses unlisted tools` |
| U25 | An `allowlist` gate with an empty `allowed` list refuses every tool (lock-down) — the inner dispatcher sees nothing | FR-004 | example | DONE | `…::U25: empty allowlist locks down all tools` |
| U26 | A `blocklist` gate refuses exactly the listed tools and delegates the rest; an empty `blocked` list delegates everything | FR-004 | example | DONE | `…::U26: blocklist gate refuses only listed tools` |
| U27 | `dispatchBatch` gates each call independently; `validateSchema` and `checkRiskTier` delegate to the inner dispatcher | FR-004, FR-007 | example | DONE | `…::U27: batch dispatch gates per call; schema/risk delegate` |
| U28 | `constrainResponse` boundaries: `maxChars` null → unchanged; content length == `maxChars` → unchanged; length == `maxChars` + 1 → truncated; long content → exactly the first `maxChars` characters + `[playbook:<id>] response truncated at <maxChars> characters` | FR-005 | example | DONE | `…::spec 104 — PlaybookRuntime response::U28: maxChars truncation boundaries` |
| U29 | With no response constraints, `constrainResponse` passes any content through unchanged | FR-005 | example | DONE | `…::U29: no constraints means no change` |
| U30 | The runtime reads time through its injected clock: `injectedAt` of generated steering messages follows the clock (advancing the clock advances the timestamp) | FR-003, FR-007 | example | DONE | `…::U30: steering timestamps come from the injected clock` |

## Invariants and edge cases still to place

- None unplaced: the spec's edge-case list maps to U7 (empty-list gates),
  U16 (no-op playbook), U5/U14 (blank tool ids), U1 (steering duplicates),
  U12 (non-map top level), U21 (no shared-state mutation). YAML *syntax*
  errors (unterminated strings etc.) are the `yaml` package's own behavior
  and propagate as its exception — deliberately not re-tested here
  (framework-under-test smell); recorded in Out of scope.

## Out of scope

- Authoring UI, remote fetching, hot-reload (issue #104 out-of-scope list).
- `extends` inheritance resolution between playbooks — that is the
  `YamlAgentSpec` mechanism (spec 005 US3 scenarios 1–2), not the playbook
  mechanism.
- Playbook persistence/serialization beyond load (no `toJson` for the
  playbook in this spec — the document is the source of truth).
- The `SteeringQueue`'s own FIFO semantics and the `SteeringInjected` event
  shape (spec 033, own test files) — this feature composes them, and the
  acceptance tests observe them end to end.
- Real LLM behavior — missions run against `ScriptedLlmClient` (spec 069
  exemplar); the model's *response* to steering is a model concern, the
  engine's *injection* of steering is the tested behavior.
- YAML syntax errors — the `yaml` package's contract, not this loader's
  (shape validation is; see U12–U15).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time, so this
file is readable on its own:

- Single test: `dart test --plain-name "{name}"`
- Full suite: `dart test`
- Analyze (changed files): `dart analyze --fatal-infos lib/src/domain/entities/playbook/ lib/src/engine/playbook_runtime.dart test/domain/entities/playbook/ test/engine/playbook_runtime_test.dart`
- Coverage (corroboration only): `dart test --coverage=<dir> <file>`
- Mutation: none — deliberate mutants on the highest-risk behaviors at
  `/speckit.tdd.verify` (no mutation tool in the dependency set)
