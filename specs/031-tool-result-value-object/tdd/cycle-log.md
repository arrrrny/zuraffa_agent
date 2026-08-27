# Cycle Log: ToolResult value object

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 562 passed, 0 failed (post spec-29)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged)
- commit: `47933af`
- recorded: cycle 0, before any spec-031 change

## Cycle 1-3 (one test-first commit, one implementation commit, three behavior groups)

The value-object semantics form one cohesive surface; the tests were written
test-first as one commit with three groups (cycle 1: isError + equality/
hashCode; cycle 2: serialization; cycle 3: oversized path), and the
implementation landed as one green commit. The red evidence is the compile
failure over the whole surface.

- test: `test/domain/entities/tool_result/tool_result_test.dart` (new, 16 tests in 3 groups)
- red: `dart test test/domain/entities/tool_result/`
  -> compile errors: `Member not found: 'ToolResult.error'`, `Member not found: 'ToolResult.success'` (factories, isError, toJson/fromJson, oversized all absent)
- green: `lib/src/domain/entities/tool_result/tool_result.dart` enriched — `isError` field (default false) + `success`/`error`/`oversized` const factories; `toJson`/`fromJson` (nested artifactRef `{kind,id,uri?}`, absent payload/ref never fabricated, `ArgumentError` on shape violations); order-independent payload hash fold (commutative sum of per-entry hashes). Suite -> 578 passed (semantics +16; the 7 pre-existing provider tests pass unchanged — FR-007)
- refactor: none — const constructors throughout, one serialization pass
- commit: test (red), `bf98bbb` (green)

## Verification experiments (recorded before verification.md)

1. **Scaffold-hashCode check**: the refined hashCode was temporarily reverted to
   the scaffold's `Object.hash(content, artifactRef)` and A7 was run — it
   **passed** on the scaffold too. Finding: the scaffold satisfies the
   ==/hashCode contract (it never touches the payload map); its weakness is
   deterministic collisions for payload-only differences (legal but poor
   distribution). The original spec/plan wording ("live contract violation")
   was WRONG and was corrected in commit `f5c4e92`. A7/U4 are contract
   regression guards, not bug-fix proofs.
2. **Incident — lost implementation**: the scaffold-hashCode experiment ran
   `git checkout` on the entity file BEFORE the refined implementation was
   committed (the earlier green run had been on uncommitted code), discarding
   it. The implementation was rewritten identically from the recorded design
   and committed (`bf98bbb`) before any further experiments. Lesson applied:
   every subsequent mutant restore was verified against committed state
   (`git diff --stat lib/` = 0).

## Notes and deviations

- Suite arithmetic: 562 (post-29) + 16 (semantics) = 578. The pre-existing
  7-test provider file is untouched and green (FR-007).
- `dart analyze` held at the 5 pre-existing issues throughout.
- The single test-first commit covers three planned cycles; the compile-level
  red is shared. Behavior-level reds within the surface were not individually
  staged because the whole file fails to compile until the surface exists —
  recorded here as the honest granularity.
