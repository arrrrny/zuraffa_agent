# Implementation Plan: Playbook-as-spec behavior steering (R5#4)

**Branch**: `104-playbook-as-spec-steering` | **Date**: 2026-08-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/104-playbook-as-spec-steering/spec.md` (seeded from issue #104)

## Summary

A playbook is a declarative, spec-shaped document. The engine gains (a) the
**playbook-as-spec schema** — a typed value object loaded from YAML/JSON with
actionable validation diagnostics; and (b) the **engine path that applies a
loaded playbook as the active steering/behavior context**: steering entries
seed the mission's `SteeringQueue` (observable as `SteeringInjected`
events), the tool gate wraps the mission's `ToolDispatcher` (typed
`tool not allowed` refusals), and response constraints shape the final
response (a language directive via steering + a mechanical `maxChars`
cap). New playbooks require only a new document — no engine file branches
on playbook identity or content. Everything composes on existing surfaces
(spec 033 steering, spec 069 mission loop, spec 070 gate contract); no
existing source file changes.

## Technical Context

**Language/Version**: Dart 3.11+ (pubspec SDK constraint `^3.8.0`; resolved
and verified on Dart 3.13.2 stable). Pure Dart engine — Flutter-free
(constitution VII).

**Primary Dependencies**: `package:yaml` (already a direct dependency,
`^3.1.4`) for document parsing; `package:test` + `package:mocktail`
(dev, already present). **No new dependencies.**

**Storage**: N/A — a playbook is handed to the loader as a document (YAML
string or JSON map); remote fetching, persistence, and hot-reload are out
of scope (issue #104).

**Testing**: `dart test` (package:test), house `test/` mirror layout
(`test/domain/entities/<entity>/<entity>_test.dart`,
`test/engine/<runtime>_test.dart`). Deterministic via injected clocks and
hand-rolled fakes (`ScriptedLlmClient`, `FakeToolDispatcher` — the spec 069
exemplar pattern).

**Target Platform**: Dart VM (library consumers); no platform channels, no
`dart:io` in the new files (purity gate, constitution VII).

**Project Type**: library (the agent engine of the Zuraffa ecosystem).

**Performance Goals**: N/A — no performance criterion in the seed issue.

**Constraints**: constitution VII (engine purity — no Flutter, no
`dart:io` in runtime paths), IX (Zorphy model layer — see Constitution
Check for the documented exemption precedent), X (post-build analysis
pristine on changed files). CI verify gate: `dart pub get` →
`dart analyze --fatal-infos` → `dart test` → purity gate → attribution
gate.

**Scale/Scope**: 3 new lib files (~600 lines), 3 new test files (~700
lines), 0 changed existing source files.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. CLI-Built Only** — PASS. This work runs through the spec-driven
  pipeline (`specify` → `plan` → `tasks` → `analyze` → `tdd` →
  `implement`); the files below are the plan's declared structure, created
  by the pipeline's own commands, not ad-hoc scaffolding.
- **II. Stop on First Misfire** — PASS. Gates run in order
  (FR-008); the loop halts at the first red that is not the intended red.
- **III. Escalate Upstream and Wait** — PASS. No framework (`zfa`,
  zuraffa) defect is worked around; the feature composes public engine
  surfaces only.
- **IV. Postmortem Every Misfire** — PASS. No misfire anticipated; any
  halt gets its postmortem per precedent.
- **V. Gates Are Non-Negotiable** — PASS. FR-008 pins analyze + test +
  purity; the spec is the contract (SC-001..SC-006).
- **VI. Probes Must Retain Evidence** — PASS. The TDD cycle log records
  every red/green run verbatim; nothing gates blind.
- **VII. Engine Purity** — PASS. No Flutter dependencies; the new runtime
  files import only `dart:core` collections and in-repo entities
  (`package:yaml` in the loader only). No `dart:io` anywhere new.
- **VIII. Attributed Ports** — PASS. Nothing is ported; all code is
  original to this spec (the schema is designed from issue #104 + spec
  005's strategy note).
- **IX. Zorphy Is the Model Layer (non-negotiable)** — PASS **with the
  house exemption precedent, documented**: the engine's recent behavior
  surfaces ship as hand-curated plain Dart value objects precisely so
  they compile without build_runner — `SteeringMessage` (spec 081,
  merged PR #103), `SubAgentSpec` (036), `MissionRunner`/`MissionResult`
  (069), `SubAgentDispatchService`/`SubAgentDispatchResult` (070). Each
  records the exemption in its header; spec 081's spec.md records it as
  "constitution IX exemption — same precedent as AgentSession PR #50,
  ToolResult PR #49, StopPolicy PR #47". The Playbook entities follow the
  same precedent, with the exemption recorded in the file header and in
  the spec's Key entities.
- **X. Post-Build Analysis Must Be Pristine** — PASS. `dart analyze
  --fatal-infos` on the changed files must report zero findings. The
  repository baseline carries 3 pre-existing findings in unrelated files
  (`test/engine/mission_runner_002_a2_test.dart:91` unused field warning,
  `lib/src/eval/cassette_replay_llm_client.dart:68` info,
  `test/engine/mission_runner_002_a3_test.dart:122` info) — recorded at
  baseline `9d0b341`, untouched by this feature, flagged in the report,
  not fixed here (out of scope, principle VI discipline).

## Project Structure

### Documentation (this feature)

```text
specs/104-playbook-as-spec-steering/
├── spec.md               # /speckit.specify output (seeded from issue #104)
├── plan.md               # This file (/speckit.plan output)
├── checklists/
│   └── requirements.md   # specify-stage quality checklist
├── tasks.md              # /speckit.tasks output
└── tdd/
    ├── test-list.md      # /speckit.tdd.plan output
    ├── cycle-log.md      # /speckit.tdd.run evidence (append-only)
    └── verification.md   # /speckit.tdd.verify audit report
```

### Source Code (repository root)

```text
lib/src/domain/entities/playbook/
├── playbook.dart         # Playbook schema value object + gate-mode enum +
│                         #   steering/tool-gate/response sub-values,
│                         #   constructor validation (FR-001, FR-002 value side)
└── playbook_loader.dart  # PlaybookLoader — YAML string / JSON map → Playbook
                          #   with typed ArgumentError diagnostics (FR-002)

lib/src/engine/
└── playbook_runtime.dart # PlaybookRuntime (US2/US3/US4 application) +
                          #   PlaybookToolGateDispatcher (FR-003/4/5/7)

test/domain/entities/playbook/
├── playbook_test.dart    # schema + validation unit behaviors
└── playbook_loader_test.dart  # document → playbook + malformed variants

test/engine/
└── playbook_runtime_test.dart # steering seeding, tool gate, response
                               #   constraints, and the US5 R5#4 acceptance
                               #   test (three documents, one code path)
```

**Structure Decision**: mirror of the existing layout —
`domain/entities/<entity>/` for value objects (like `steering_message/`,
`sub_agent_spec/`), `engine/` for runtimes (like `mission_runner.dart`,
`sub_agent_dispatch.dart`), tests mirrored under `test/`. Nothing is
exported from `lib/zuraffa_agent.dart` — consistent with the sibling
engine runtimes (069/070 headers document this).

## Components

### 1. Playbook schema value object — `lib/src/domain/entities/playbook/playbook.dart` (US1 / FR-001)

- `enum PlaybookGateMode { off, allowlist, blocklist }`
- `PlaybookSteering` — `{String? id, String content}` (content required,
  non-empty; entry id optional), value equality.
- `PlaybookToolGate` — `{PlaybookGateMode mode, List<String> allowed,
  List<String> blocked}`; constructor rejects blank ids in either list and
  the mode/list inconsistency: a non-empty `blocked` list on an
  `allowlist` gate, a non-empty `allowed` list on a `blocklist` gate, and
  non-empty lists of any kind on an `off` gate (a useless list is loader
  drift); empty lists are inert and always legal. Value equality.
- `PlaybookResponse` — `{String? language, int? maxChars}`; constructor
  rejects blank language and `maxChars < 1`. Value equality.
- `Playbook` — identity (`id`, `name`, `description` — required
  non-empty; `domain`, `country` optional non-empty-when-present) +
  `steering` (ordered, duplicates preserved) + `toolGate` + `response`;
  full value equality + `hashCode` across all fields; `toString` in the
  house style.
- All validation throws `ArgumentError.value` naming the offending field
  (house pattern: `SteeringMessage.fromJson`, `SubAgentSpec`
  constructor).

### 2. Playbook loader — `lib/src/domain/entities/playbook/playbook_loader.dart` (US1 / FR-002)

- `PlaybookLoader.loadYaml(String source)` — `yaml.loadYaml` → must be a
  `Map`; every section key type-checked; delegates to `loadJson`.
- `PlaybookLoader.loadJson(Map<String, dynamic> json)` — required-key and
  type checks with `ArgumentError` naming the offending key (missing
  `id`/`name`/`description`, non-string identity, `steering` not a list,
  entry without `content`, blank `content`, `toolGating.mode` outside the
  three legal values, mode/list inconsistency, blank tool ids,
  `response.maxChars` not a positive int, `response.language` blank),
  then constructs the value object (which re-validates invariants — the
  constructor is the single source of truth for value invariants).
- Document fields the schema does not know are ignored? **No** — MVP
  decision: unknown top-level keys are ignored (forward compatibility —
  a newer playbook must not crash an older engine), but every *known*
  key is strictly validated. Recorded as a design decision here.

### 3. Playbook runtime — `lib/src/engine/playbook_runtime.dart` (US2/US3/US4 / FR-003..FR-007)

- `PlaybookRuntime({required Playbook playbook, DateTime Function()? clock})`
  — clock injectable (house pattern, spec 069), default `DateTime.now`.
- `List<SteeringMessage> steeringMessages()` — one `SteeringMessage` per
  steering entry: `id: entry.id ?? 'pb-<playbookId>-steer-<index>'`,
  `content: entry.content`, `injectedAt: clock()`; plus, when
  `response.language` is set, one directive message appended:
  `id: 'pb-<playbookId>-lang'`, `content: "[playbook:<id>] Respond in
  language '<language>'."` (the exact rendering is pinned by FR-005 and
  the tests — playbook-attributable so observers can trace steering to
  the document).
- `SteeringQueue seedSteering(SteeringQueue queue)` — pure value
  composition: `queue.enqueue(...)` per message, FIFO in document order;
  the input queue is never mutated (FR-007).
- `ToolDispatcher gateDispatcher(ToolDispatcher inner)` — returns a
  `PlaybookToolGateDispatcher` implementing the spec 070
  `AllowlistToolDispatcher` contract: refused calls yield
  `ToolDispatchResult(success: false, result: '', error: 'tool not
  allowed: $toolName', artifactRefs: const [])` and the inner dispatcher
  never sees them; `off` delegates everything; `validateSchema` /
  `checkRiskTier` / `dispatchBatch` delegate (batch = per-call gate,
  same as 070).
- `String constrainResponse(String content)` — `maxChars == null ||
  content.length <= maxChars` → unchanged; else exactly
  `content.substring(0, maxChars)` followed by
  `'[playbook:<id>] response truncated at <maxChars> characters'`.

### 4. The R5#4 acceptance composition — `test/engine/playbook_runtime_test.dart` (US5 / FR-006 / SC-005)

The acceptance test is a composition through the **real entry points**:
`PlaybookLoader.loadYaml` → `PlaybookRuntime` → seeded `SteeringQueue` +
gated `FakeToolDispatcher` → `MissionRunner.run` with a
`ScriptedLlmClient` (spec 069 exemplar fakes, fixed clock) → assert on
the emitted `EngineEvent` stream, the transcript, tool-refusal records,
and the constrained summary. Three documents (Germany, Japan, and a
third novel inline document) run through the **identical** code path —
the test never branches on playbook identity, proving FR-006 (adding a
playbook = adding a document).

## Sequencing

1. `/speckit.tasks` — task breakdown (below).
2. `/speckit.analyze` — cross-artifact drift check; fix findings.
3. `/speckit.tdd.setup` — write `.specify/memory/tdd-profile.md`
   (Dart stack: `dart test`, single-test `-n`, no mutation/property
   tools in the dependency set — deliberate mutants instead).
4. `/speckit.tdd.plan` — derive `tdd/test-list.md` from spec.md + this
   plan; make test tasks mandatory and ordered before implementation.
5. `/speckit.tdd.run` — red-green-refactor, one behavior per cycle,
   evidence in `tdd/cycle-log.md`, commit at green per house cadence
   (`test(104):` / `feat(104):` convention from git log).
6. `/speckit.implement` — any remaining non-behavioral wiring (the loop
   deliberately leaves scaffolding/config to this phase).
7. `/speckit.tdd.verify` — cold-context audit → `tdd/verification.md`.
8. Gates: `dart analyze --fatal-infos` (changed files pristine) +
   `dart test` (baseline 1163 + new, green) + purity gate.
9. Commit spec-kit artifacts + push + PR (base `master`, closes #104).

## Complexity Tracking

> No constitution violations need justification (check above passes; the
> IX exemption is the documented house precedent, not a violation).
