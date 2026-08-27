---
feature: 034-agent-tool-risk-tier
verdict: PASS
verified_at: 22a4d7b
behaviors_total: 15
behaviors_done: 15
test_first: 14 PROVEN (compile-level red + probe-documented assertion red), 1 NOT_APPLICABLE (U6 baseline)
mutation: 4/5 killed, 1 equivalent-by-design (M1b fold-drop — the 031 M5 precedent, documented)
criteria_covered: 9/9 acceptance criteria, 7/7 FRs
suite: 640 passed, 0 failed
analyze: 0 issues (No issues found, --fatal-infos)
---

# TDD Verification: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

## Verdict

**PASS** — the tier/mode classification surface (`fromString` with typed
failures that never silently under-classify), the registry persistence
contract (`toJson`/`fromJson` with tier/mode names and deep schema), and
the `hashCode` contract fix (recursive order-independent schema fold
replacing the scaffold's identity-hash of the schema Map) are traced to
passing tests through the declaration value object's public API; the
change landed test-first with compile-level red evidence plus a
pre-planning probe that documents A1's assertion-level red against the
unmodified scaffold; four of five deliberate mutants were killed, the
fifth being equivalent-by-design with the spec-031 M5 precedent; the ten
pre-existing provider/compile-parity tests pass unchanged.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A1..A9 + U1..U5 | test-only commit `5f48d58` precedes the implementation commit `22a4d7b`; red recorded as compile errors (`fromString`/`toJson`/`fromJson` undefined — 22 error sites, loading failure). A1's assertion-level red against the scaffold is documented by the pre-planning probe (cycle log): `a == b` → true, hashCodes 518580394 vs 128524753 — a live `==`/`hashCode` contract violation, experimentally verified before being claimed in the spec |
| NOT_APPLICABLE | U6 (10 pre-existing provider/compile-parity tests) | green against untouched layers (FR-001, FR-005, FR-007) |

Honest granularity note: the three planned behavior groups share one
test-first commit (the file does not compile until the surface exists).
The scaffold's live violation means A1 is a bug-fix proof, not merely a
regression guard — contrast spec 031, whose scaffold hash was
contract-legal.

Changes to pre-existing tests: NONE — verified in the green run and again
after every mutant restore. Notably, the pre-existing equality test
constructs both tools with the SAME schema instance, so it never
exercised the violation — exactly the blind spot A1 closes.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 scaffold's identity-hash bug restored | schema Map passed through `Object.hash` | A1 | KILLED — `Expected: <96583394>, Actual: <447915222>` — the mutant the fix exists to kill |
| M1b schema fold dropped entirely | fold replaced by constant 0 | A1/A2 | SURVIVED — **equivalent-by-design**: a hash excluding the schema is contract-legal (equal tools hash equally); only distribution weakens, and distribution is not deterministically assertable because collisions are legal (spec-031 M5 precedent). Documented, not remediated |
| M2 fold stops at depth 1 | nested map values hashed by identity | U3 | KILLED — `Expected: <209802726>, Actual: <434840353>` |
| M3 fromString silent safe default | unknown tier → `RiskTier.safe` | A5 | KILLED — `Expected: throws ArgumentError, Actual: Closure` — under-classification caught |
| M4 fromJson unknown tier → safe | catch swallows, defaults | A9 | KILLED — `Expected: throws ArgumentError with name: 'riskTier', Actual: Closure` |

Every mutant was restored exactly (`git diff --stat lib/` = 0) and the
affected file re-run green (+14 passed).

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 tier strings parse + round-trip | A4 | PROVED |
| AC US1-2 unknown strings fail typed | A5, U2 (+M3 killed) | PROVED |
| AC US1-3 dispatch-policy reads per tier | A6 | PROVED (existing surface, re-pinned) |
| AC US2-1 full declaration round-trip | A7 | PROVED |
| AC US2-2 schema-less omits paramsSchema | A8 | PROVED |
| AC US2-3 malformed JSON fails typed | A9, U5 (+M4 killed) | PROVED |
| AC US3-1 equal tools hash equally | A1 (+M1 killed — the live violation) | PROVED (bug-fix proof) |
| AC US3-2 order-independent hashing | A2, U3 (+M2 killed) | PROVED |
| AC US3-3 per-axis inequality | A3 | PROVED |

FR-001..FR-007 traced (FR-005 by the untouched green enum/provider tests;
FR-006 by A1/A2/U3 + M1/M2 killed); SC-001..SC-007 proved (SC-007 via
final gates below).

## Final gates

- `dart analyze --fatal-infos` — No issues found (0; zero new).
- `dart test` — 640 passed, 0 failed (post-033 baseline 626 + 14 new).
- Constitution VII — no `dart:io` in the new/changed files; IX —
  hand-curated plain-Dart exception documented in the file header,
  unchanged by the refinement.

## Remediation

- T017: the registry's registration-time collision rejection should build
  on the fixed hash (a `Set`/`Map` keyed by `AgentTool` now dedups
  correctly); wire it when the tool_registry spec (047) consumes this
  surface.
- T018: dispatch-time params validation against `paramsSchema` (R3.1)
  belongs to the dispatcher's spec; the declaration ships the schema.
- T019: the datasource-interface + mock-datasource pair the original task
  text named stays with the datasource-pair spec family (025/027/029
  precedent) — recorded here so the gap is deliberate, not forgotten.
