---
feature: 014-stop-policy-clean-arch-layers
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 3
proven: 0
likely: 0
test_after: 3
no_test: 0
high_smells: 1
criteria_total: 3 # no numbered ACs; spec Files + plan Phase 1 require the repository, service, and provider surfaces
criteria_covered: 3
mutation_score: null # no mutation tool in the lockfile (profile: mutation = null)
mutants_survived: 0 # of 2 deliberate mutants
suite: 1072 passed, 2 skipped, 0 failed, 81s (`dart test`)
---

# TDD Verification: StopPolicy clean-architecture layers

**Verdict: FAIL.** All three behaviors are `TEST_AFTER`: the layers shipped
together with their tests in `7eb6c7c` and this feature's cycle log records no red
at all. One test also proves nothing — `U11` asserts only that a
just-constructed `StopPolicyProvider` is `isNotNull`. The behavioral core is
otherwise sound: both deliberate mutants (provider bypassing the datasource,
repository swallowing an id mismatch) were caught.

## Test-first evidence

`specs/014-stop-policy-clean-arch-layers/tdd/cycle-log.md` contains **only** the
Baseline entry (`fce207d`, 909 passed): no cycle, no red command, no failure
output. `test-list.md:13-16` says so directly ("this is a **test-after** plan …
No `RED` cycles were driven because the implementation preceded the list").

History for the three shipped layers:

- `7eb6c7c` — `fix(stop_policy): hand-curate clean-arch layers (repository, service, provider) (closes #14) (#48)` — 175 insertions, 0 deletions: `stop_policy_repository.dart`, `stop_policy_service.dart`, `stop_policy_provider.dart`, the spec/plan/tasks, **and** a 59-line `test/data/providers/stop_policy/stop_policy_provider_test.dart`, all in one commit. No red recorded.
- Later, under spec 027: `8de8f41` `test(spec 027): add StopPolicyRepositoryImpl seam tests (red)` (test-only, 92 insertions) → `541414a` `feat(spec 027): fix import depth + test expectation in repository impl (green)`; and `34da014` `test(spec 027): add provider chain-consumption tests (red)` (test-only, +64/−35) → `8e170bf` `feat(spec 027): rewrite provider to consume the datasource (green)`.

The spec-027 pairs do show the disciplined shape (test-only commit, then source),
which is why the behaviors are graded on the shipped state rather than dismissed —
but the reds belong to spec 027's cycle log, not this one, and the layers this spec
introduces predate them. Fail closed:

| Behavior | Class      | Evidence                                                                                                                                                                                                                             |
| -------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| U1       | TEST_AFTER | `stop_policy_repository.dart` shipped in `7eb6c7c`; the test file U1 points at (`stop_policy_repository_impl_test.dart`) was created five commits later in `8de8f41`. No red in this feature's cycle log.                              |
| U2       | TEST_AFTER | `stop_policy_service.dart` + `stop_policy_provider.dart` and their test all landed together in `7eb6c7c` with no red recorded — the rubric grades a combined commit as `PROVEN` only when the cycle log carries its red. It does not. |
| U3       | TEST_AFTER | The datasource-consuming behavior was driven under spec 027 (`34da014` → `8e170bf`); no red is recorded for this feature.                                                                                                             |

**Changed-test check.** `34da014` rewrote the pre-existing provider test file
(+64/−35), replacing the `UnimplementedError` stub assertions with the
chain-consumption assertions now in the tree. This is a legitimate behavior change
(the provider was intentionally rewritten in `8e170bf`), not a weakening: the new
assertions are strictly stronger — `equals(StopPolicy.defaultPolicy)` /
`equals(strict)` value comparisons replaced `throwsA(isA<UnimplementedError>())`.
The residue is that `spec.md:13-14` still describes the old stub behavior
(finding #4). No test was skipped, renamed out of a filter, or excluded, and no
coverage threshold was reduced.

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                                                                                                                       | Evidence                                                                             |
| --- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 1   | HIGH     | **Vacuous assertion.** `U11: parameterless StopPolicyProvider() keeps compiling (default wiring)` constructs the provider and asserts `expect(provider, isNotNull)` — a Dart constructor cannot return null, so the assertion can never fail. The behavior it means to pin ("default wiring") should be asserted instead: that a parameterless provider reads through a real default datasource, e.g. `expect(await provider.current(NoParams()), equals(StopPolicy.defaultPolicy))` plus a mutation-visible check that the default datasource is a `StopPolicyMockDatasource`. | `test/data/providers/stop_policy/stop_policy_provider_test.dart:27-30`                |
| 2   | HIGH     | **All three behaviors are `TEST_AFTER`.** No red exists for this feature; the cycle log holds only a baseline. Under the rubric this alone is a `FAIL`.                                                                                                                                                                              | `specs/014-stop-policy-clean-arch-layers/tdd/cycle-log.md:1-10`; `test-list.md:13-16` |
| 3   | MED      | **`tasks.md` and `test-list.md` name a test that does not carry the behavior they describe.** U1's behavior text is "impl delegates + `StateError` on unknown id", but the named test is `U8: StopPolicyRepositoryImpl is a StopPolicyRepository` — a bare `isA<>` assertion (`stop_policy_repository_impl_test.dart:16-21`). The delegation and `StateError` claims are actually covered by *other* tests in that file (`:23`, `:40`, `:48`, `:62`, `:76`), which the list never names. The `traces` pointer resolves to a real test, but not to the asserted behavior. | `specs/014-stop-policy-clean-arch-layers/tasks.md:2`; `test-list.md:30`               |
| 4   | MED      | **`spec.md` describes code that no longer exists.** It states the provider is a "concrete `StopPolicyProvider` stub (implements StopPolicyService with matching NoParams signatures)" and the test file holds "5 regression tests (is-A, UnimplementedError bodies, type-bound sentinels)". The shipped provider consumes a datasource and throws nothing (`stop_policy_provider.dart:38-42`); the test file holds 7 tests and no `UnimplementedError` assertion. `test-list.md:51-58` already reports this; the spec was never corrected. | `specs/014-stop-policy-clean-arch-layers/spec.md:13-14`                               |
| 5   | MED      | **Ownership drift: both test files declare themselves spec 027.** `stop_policy_provider_test.dart:1` (`// Spec 27 — … (TDD cycle 4)`) and `stop_policy_repository_impl_test.dart:1` (`// Spec 27 — … (TDD cycle 3)`) trace to spec 027's test list, ids `A1..A6`/`U8..U12`. Nothing in either file connects it to this feature's U1–U3, so the audit trail runs only one way. | `test/data/providers/stop_policy/stop_policy_provider_test.dart:1-10`; `test/data/repositories/stop_policy_repository_impl_test.dart:1-5` |
| 6   | MED      | **The repository interface's `update`/`reset` return contracts are unpinned.** `StopPolicyRepository.update` returns `Future<StopPolicy>` (`stop_policy_repository_impl.dart:43`) but every test discards the return value (`:57`, `:71`, `:79`, `:85`), asserting the side effect through a subsequent read instead. A change to what `update` returns would go unnoticed. | `test/data/repositories/stop_policy_repository_impl_test.dart:48-60`                  |
| 7   | MED      | **`reset(String id)` ignores its parameter and no test notices.** The impl delegates to `_datasource.reset()` regardless of `id` (`stop_policy_repository_impl.dart:46`); the U9 reset test passes `'strict'` and then reads `'default'`, so passing any id at all would pass. Either the parameter carries a rule that needs pinning, or it should not be in the signature. | `test/data/repositories/stop_policy_repository_impl_test.dart:62-74`                  |
| 8   | LOW      | **Redundant `isA<>` bookkeeping.** `U10` (`:23`) and `U8` (`repository_impl_test.dart:16`) assert interface conformance that `dart analyze --fatal-infos` already enforces at compile time, and `:86` re-asserts `ds is StopPolicyDatasource` inside a behavior test. | `stop_policy_provider_test.dart:23,86`                                               |
| 9   | LOW      | **Duplicated setup / magic values.** The `const StopPolicy(id: 'strict', maxTurns: 3, wallClockTimeout: Duration(seconds: 30), repetitionThreshold: 2)` block is copied five times across the two files with no factory and no explanation of the numbers. | `stop_policy_provider_test.dart:39,55`; `stop_policy_repository_impl_test.dart:25,65` |

Suite properties: both files are isolated (a fresh `StopPolicyMockDatasource` per
test), deterministic (no clock, random, network, sleep, or ordering dependence),
and fast (54 tests across the five audited files in ~2s). The provider tests use
the real datasource rather than a mock, so they are not over-mocked; there is no
doubled subject.

## Mutation results

No mutation tool in this repository (`.specify/memory/tdd-profile.md`:
`mutation: null`), so deliberate mutants were used. **2 of 3 behaviors sampled**
(U3 — the provider→datasource chain; U1 — the repository's id-mismatch guard),
chosen as the two whose failure would silently serve a wrong policy to the engine
loop. Each mutant was applied, the behavior's test file run, then the source
restored from a pristine copy and verified with `git diff --quiet`; the audited
files were re-run green (54 passed) and the full suite re-run green (1072 passed,
2 skipped).

| Mutant                                                                                                                                          | Behavior | Survived | Judgment                                                                                                                              |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| M1 `lib/src/data/providers/stop_policy/stop_policy_provider.dart:39` — `current(NoParams)` returns `StopPolicy.defaultPolicy` instead of delegating to `_datasource.current()` | U3       | No       | Caught by 3 tests (A2+A5, A4, A5): `Expected: StopPolicy(id: strict…) Actual: StopPolicy(id: default…)`. The datasource seam is pinned. |
| M2 `lib/src/data/repositories/stop_policy_repository_impl.dart:32` — `if (policy.id != id)` → `if (false)` (id-mismatch guard removed)            | U1       | No       | Caught by 3 tests (U9, A6, edge-2): `Expected: throws <Instance of 'StateError'>`. The wrong-id guard is pinned.                        |

No survivors. U2 (service surface / provider conformance) was **not** sampled: its
only non-vacuous assertion is `defaultPolicy(NoParams)` returning the canonical
constant, and the equivalent mutant there is the same one already exercised as M2
in the sibling `013-stop-policy-duration-fields` audit.

## Traceability

This spec is a short PR-style document with **no numbered acceptance scenarios**
(`test-list.md` frontmatter: `spec_criteria: 0`). The three criteria graded are the
surfaces `spec.md` Files and `plan.md` Phase 1 require:

| Criterion                                                                                     | Behaviors | Tests                                                                                    | End to end |
| --------------------------------------------------------------------------------------------- | --------- | ---------------------------------------------------------------------------------------- | ---------- |
| `StopPolicyRepository`: `getCurrent(id)` / `update(policy)` / `reset(id)`, no CRUD             | U1        | `stop_policy_repository_impl_test.dart:16,23,40,48,62,76`                                 | Yes — real impl over the real mock datasource, no doubles |
| `StopPolicyService`: `current(NoParams)` / `defaultPolicy(NoParams)`, parameterless (PR #32)   | U2        | `stop_policy_provider_test.dart:23,27,68`                                                 | Partial — one real assertion (`:68`); `:23` is compile-time, `:27` is vacuous (finding #1) |
| `StopPolicyProvider`: concrete `StopPolicyService` over the datasource                          | U3        | `stop_policy_provider_test.dart:32,37,51,73`                                              | Yes — real chain provider→datasource |

Untested criteria: none of the three, though the service surface is covered too
thinly to count as verified (finding #1). Tests tracing to nothing:
`U10` (`:23`) and the `expect(ds, isA<StopPolicyDatasource>())` tail at `:86`
assert no requirement in `spec.md` or `plan.md`. Conversely, five tests in
`stop_policy_repository_impl_test.dart` carry U1's real content while the list
names only `U8` (finding #3).

`tasks.md` cross-check: `[U1]`, `[U2]`, `[U3]` are ticked `[x]` and all three are
`DONE` in `test-list.md`. No ticked task points at a non-`DONE` behavior. `T1`–`T7`
carry no checkbox, so nothing is over-claimed there.

## What was not audited

- **Coverage was not collected** for the three layer files, so uncovered-branch corroboration is absent.
- **U2 was not mutation-sampled** (see above).
- **`StopPolicy` value-object semantics** (the 5 fields, equality) are out of scope here — spec `013-stop-policy-duration-fields` owns them and is audited separately.
- **The datasource pair itself** (`StopPolicyDatasource` / `StopPolicyMockDatasource`) belongs to spec 027 and was used as a real collaborator, not graded.
- **`Loggable` / `FailureHandler` mixin behavior** (`stop_policy_provider.dart:31`, `stop_policy_repository_impl.dart:23`) — no behavior claims it and no test asserts logging or failure mapping.
- **A persistent (Hive / remote) datasource** — the seam's stated purpose (`stop_policy_repository_impl.dart:6-8`) is never exercised against a non-mock backend.
- **The zfa-generator claim** in `spec.md` ("`zfa make` crashes with `type 'bool' is not a subtype of type 'String?'`") was not reproduced; no zfa invocation was made.
- **Performance / concurrency**: no criterion, no test, not assessed.
