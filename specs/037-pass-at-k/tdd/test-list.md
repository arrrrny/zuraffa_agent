---
feature: 037-pass-at-k
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 5
planned_at: 57412fe
updated_at: 627d7c2
suite_baseline: green
---

# Test List: PassAtK unbiased estimator (eval-run + threshold slice)

## Outer loop: acceptance behaviors

Pure value object — the public API (factories, methods) is the entry point the
harness consumes; `loop: inside-out`.

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| A1  | fromResults over a 10-outcome run (6 true, k=3) equals compute on the triple    | AC US1-1 | example         | DONE    | `pass_at_k_test.dart` (red @ `e8b6e9a`) |
| A2  | fromResults throws on empty outcomes / k<1 / k>n; order-independent             | AC US1-2 | example         | DONE    | `pass_at_k_test.dart` (red @ `e8b6e9a`) |
| A3  | meetsThreshold is inclusive at t==value and flips on both sides                 | AC US2-1 | example         | DONE    | `pass_at_k_test.dart` (red @ `8e0580a`, M4 killed) |
| A4  | meetsThreshold throws on t<0 / t>1 / NaN                                        | AC US2-2 | example         | DONE    | `pass_at_k_test.dart` (red @ `8e0580a`) |
| A5  | k-sweep 1..n-c yields non-decreasing pass@k                                     | AC US3-1 | characterization | DONE (BASELINE + pin, MUTANT-C killed) | `pass_at_k_test.dart` (`627d7c2`) |

## Inner loop: unit behaviors

### `lib/src/domain/entities/pass_at_k/pass_at_k.dart`

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U1  | fromResults derives n=length, c=trueCount and matches compute exactly           | FR-001   | example         | DONE    | `pass_at_k_test.dart` (red @ `e8b6e9a`, M3 killed) |
| U2  | fromResults: empty outcomes ArgumentError; k=0 and k=n+1 ArgumentError; shuffled fixture equals sorted fixture | FR-001   | example         | DONE    | `pass_at_k_test.dart` (red @ `e8b6e9a`) |
| U3  | meetsThreshold(t==value) true, t below true, t above false (both sides)         | FR-002   | example         | DONE    | `pass_at_k_test.dart` (red @ `8e0580a`, M4 killed) |
| U4  | meetsThreshold: -0.1, 1.1, NaN all throw ArgumentError naming threshold         | FR-002   | example         | DONE    | `pass_at_k_test.dart` (red @ `8e0580a`) |
| U5  | Monotonic non-decreasing in k for 1 <= k <= n-c (n=20, c=4 sweep)               | FR-003   | characterization | DONE (BASELINE + pin, MUTANT-C killed) | `pass_at_k_test.dart` (`627d7c2`) |

### Shipped estimator surface (untouched — FR-004) + clean-arch layers (FR-005)

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U6  | compute validation + formula + endpoints (0 at c=0, 1 at n-c<k) keep passing    | FR-004   | characterization | BASELINE | `test/data/providers/pass_at_k/pass_at_k_provider_test.dart` (10 metric tests) |
| U7  | binomial helper + (n,c,k) equality + toString keep passing                      | FR-004   | characterization | BASELINE | `test/data/providers/pass_at_k/pass_at_k_provider_test.dart` |
| U8  | The 3 clean-arch stub tests keep passing unchanged                              | FR-005   | characterization | BASELINE | `test/data/providers/pass_at_k/pass_at_k_provider_test.dart` |

## Invariants and edge cases still to place

- fromResults delegating to compute keeps ONE validation source of truth; no
  duplicated bound logic to drift.
- Doubles compare via closeTo(1e-12) in the match test — bit-exact equality is
  expected (same arithmetic path) but closeTo documents tolerance honestly.

## Out of scope

- Wiring PassAtKProvider to the eval ledger: separate feature; FR-005 pins stubs.
- pass^k (empirical) metric: spec 061-pass_k_empirical owns it.
- Grader matrix (exact/schema/model-judge): issue #7 later PRs.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: raw VM-format only; converter absent — corroboration only, never a gate
- Mutation: no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
