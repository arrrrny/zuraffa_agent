# TDD Cycle Log: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

Append only. Newest last. Every entry's `red` block is the evidence that the
test existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 626 passed, 0 failed (~27s)
- analyze: `dart analyze --fatal-infos` -> No issues found
- commit: `34b47f8`
- recorded: cycle 0, before any change

## Probe (pre-planning evidence, 2026-08-27)

The suspected scaffold hashCode violation was verified BEFORE being written
into the spec (031 discipline — claims are tested, not assumed):

```text
dart run tool/probe_agent_tool_hash.dart  (probe since removed; script at
/home/z/my-project/scripts/probe_agent_tool_hash.dart)
  a == b: true
  a.hashCode: 518580394
  b.hashCode: 128524753
  CONTRACT VIOLATION (equal objects, different hashes)
```

Two tools with distinct-but-equal `paramsSchema` map instances: `==` is true
(deep `_mapEq`) while `Object.hash(..., paramsSchema)` hashes the Map by
identity. Unlike spec 031's scaffold (contract-legal, poor distribution),
this is a genuine `==`/`hashCode` violation — A1 is a live red, not a
regression guard.

## Cycles 1-3 — A1..A9 + U1..U5 (one test-first commit, three behavior groups)

- **Red**: compile errors — `dart test
  test/domain/entities/agent_tool/agent_tool_test.dart` -> loading
  failure; 22 error sites: `The method 'fromString' isn't defined for the
  type 'RiskTier'/'ExecutionMode'`, `'toJson'`/`'fromJson'` not defined
  for `AgentTool`. A1's assertion-level red against the scaffold is
  independently documented by the probe above (the compile red masks it in
  the runner; the probe ran against the scaffold with no test-side code).
- **Commit (test-first)**: `5f48d58`.
- **Green**: implemented `RiskTier.fromString`/`ExecutionMode.fromString`
  (exact-match, typed ArgumentError), `toJson`/`fromJson` (tier/mode as
  names, deep schema copy, malformed input fails typed; tier/mode routed
  through fromString), and the hashCode fix (recursive order-independent
  `_foldHash`; equality untouched). One transient test-side compile error
  (instance access to the static `fromString`) fixed pre-commit —
  test-side only, no implementation existed to change. Semantics file +14
  green on first run (incl. the formerly-live A1 violation test);
  pre-existing provider tests +10 green unchanged; full suite 640 passed
  (baseline 626 + 14); `dart analyze --fatal-infos` No issues found.
- **Commit (green)**: `22a4d7b`.

## Mutation runs (deliberate hand-mutants)

Each mutant was applied to `lib/src/domain/entities/agent_tool/
agent_tool.dart`, run against the named test, restored exactly
(`git diff --stat lib/` = 0), and the file re-run green after restore.

- M1 scaffold's own identity-hash bug restored (schema Map passed through
  `Object.hash`) -> **KILLED** by A1: `Expected: <96583394>`,
  `Actual: <447915222>` (+0 -1). This is the mutant the fix exists to
  kill — the live violation.
- M1b schema fold dropped entirely (fold replaced by constant 0) ->
  **SURVIVED — equivalent-by-design**: a hash that excludes the schema is
  contract-legal (equal tools hash equally); only the distribution
  weakens (schema-only differences collide), and hash distribution is not
  deterministically assertable because collisions are legal. Same verdict
  and reasoning as spec 031's M5. Documented, not remediated.
- M2 fold stops at depth 1 (nested map values hashed by identity) ->
  **KILLED** by U3: `Expected: <209802726>`, `Actual: <434840353>`
  (+0 -1) — distinct-but-equal nested instances must hash equally.
- M3 fromString silently returns safe on unknown input -> **KILLED** by
  A5: `Expected: throws <Instance of 'ArgumentError'>`, `Actual:
  <Closure: () => RiskTier>` (+0 -1) — under-classification caught.
- M4 fromJson ignores an unknown tier string and defaults to safe ->
  **KILLED** by A9: `Expected: throws ArgumentError with name: 'riskTier'`,
  `Actual: <Closure: () => AgentTool>` (+0 -1).

## Notes and deviations

- Honest granularity note (house precedent, specs 031/032/033): the three
  planned behavior groups (hash contract / classification / persistence)
  share one test-first commit; the red is compile-level for the parser and
  serialization surface, and assertion-level for A1 via the pre-planning
  probe (which ran against the unmodified scaffold).
- Changes to pre-existing tests: NONE — the 10 pre-existing provider tests
  pass unchanged (verified in the green run and after every mutant
  restore). Their equality test constructs both tools with the SAME schema
  instance, so it never exercised the violation — exactly the blind spot
  A1 closes.
