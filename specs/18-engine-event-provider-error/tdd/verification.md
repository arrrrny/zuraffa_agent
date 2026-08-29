---
feature: 18-engine-event-provider-error
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 8
proven: 0
likely: 0
test_after: 8
no_test: 0
high_smells: 0
criteria_total: 4 # test-list derives 4 acceptance behaviors (A1-A4) from spec.md Files + Verification; spec.md declares no explicit SC/FR ids
criteria_covered: 4
mutation_score: n/a # deliberate mutants NOT sampled — low-risk value object, no auth/secrets/persistence/money path; prior verification.md claimed M1-M3 killed + M4 survivor but was not re-run by this cold audit
mutants_survived: n/a
suite: 40 passed in test/engine/events/engine_event_test.dart (incl. #18 group: 3); full suite green at HEAD 01618f3
---

# TDD Verification: EngineEvent.ProviderError

**Verdict: FAIL.** The feature code (`provider_error.dart` part file + the
`engine_event.dart` switch arm) landed on master via PR #40 (issue #18) **before**
this TDD pass ran, and no `cycle-log.md` exists for this spec, so no red is
recorded for any behavior. Per the rubric, a behavior with no recorded red and a
source change that predates the pass is `TEST_AFTER`, and any `TEST_AFTER`
behavior fails the verdict. The shipped tests are green and smell-free and the
dedicated routing assertion exists, but TDD discipline is not certifiable for
this feature from the available evidence.

## Test-first evidence

| Behavior | Class     | Evidence |
| -------- | --------- | -------- |
| A1 is-A + is-ProviderError | TEST_AFTER | `test/engine/events/engine_event_test.dart::#18 group::ProviderError is an EngineEvent` — landed with PR #40; no cycle-log; source predates this pass. |
| A2 payload fields (`providerName` != `error`, distinct values) | TEST_AFTER | `#18 group::ProviderError carries payload fields` — strengthened this cycle per test-list, but still no recorded red; code predates pass. |
| A3 `dart analyze --fatal-infos` | TEST_AFTER | gate; exit 0 at HEAD; no red recorded. |
| A4 `dart test` full suite | TEST_AFTER | gate; green at HEAD; no red recorded. |
| U1 value semantics / immutable part | TEST_AFTER | `provider_error.dart` part file predates pass (PR #40); no red. |
| U2 `providerName`/`error` no cross-binding | TEST_AFTER | no red recorded; source predates pass. |
| U3 `part 'provider_error.dart';` directive | TEST_AFTER | gate proven only by analyze; no red. |
| U4 switch routes to `provider_error(providerName)` | TEST_AFTER | dedicated routing test added this cycle (test-list) but no cycle-log red for it; classified test-after per rubric. |

No `cycle-log.md` exists for this spec (only `test-list.md` + a prior
`verification.md`). The prior `verification.md` mis-classified A2/U1/U2 as
`PROVEN` and cited `.specify/memory/tdd-profile.md` as the `standard:` — both
violate the rubric (no cycle-log red ⇒ not PROVEN; `standard:` must name the
rubric). This cold audit corrects those grades.

## Findings

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | LOW | Prior `verification.md` graded several behaviors `PROVEN` with no cycle-log red and named the profile (not the rubric) as `standard:`; overwritten by this audit. | `specs/18-engine-event-provider-error/tdd/verification.md` (prior) |
| 2   | LOW | `test/engine/events/engine_event_test.dart:359` spec-066 `ProviderError equality, hashCode, toString` covers U1 value semantics but is not recorded in the test-list trace column (test traces to nothing in the list). | `test/engine/events/engine_event_test.dart:359-367` |

No existing tests were weakened or skipped. The #18 group payload test uses
distinct `providerName` ('openai') and `error` ('401 unauthorized (terminal)')
values, so a cross-binding defect would be caught.

## Mutation results

Deliberate mutants were **not** sampled for this spec. The rubric scopes mutants
to highest-risk behaviors (auth/secrets/persistence/money/acceptance-criterion
paths); `ProviderError` is a low-risk immutable value object with no such path.
The acceptance-criterion behaviors (is-A, payload round-trip, analyze gate,
full-suite gate) are covered by green tests. The prior `verification.md` reported
deliberate mutants M1-M3 killed and M4 (drop `final`) survived, but those were
not independently re-run by this cold audit and are not relied upon here.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| A1 is-A identity | `ProviderError is an EngineEvent` | Yes — value object, public API |
| A2 payload value-object (distinct `providerName`/`error`) | `ProviderError carries payload fields` | Yes |
| A3 analyze gate | CI `dart analyze --fatal-infos` | Yes (gate) |
| A4 full-suite gate | `dart test` | Yes (gate) |

Untested criteria: none. Tests tracing to nothing: the spec-066 value-semantics
test (finding #2) — valid coverage, unrecorded in the list.

## What was not audited

- Test-first red evidence: absent (no cycle-log; code merged pre-pass). Graded
  `TEST_AFTER`, not `PROVEN`.
- Deliberate mutants: not sampled (low-risk value object, out of highest-risk
  scope).
- Coverage: `package:coverage` not installed; not measured.
- Emission of `ProviderError` by the fallback-chain runtime (spec-004/008) is out
  of scope.
