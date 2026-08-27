---
feature: 27-stop_policy-datasource-pair
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 6
planned_at: 58c9062
updated_at: 658a3d0
suite_baseline: green
---

# Test List: StopPolicy datasource + mock pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. Each stays red until the feature works
end to end through its real entry point — the service/provider chain the engine
would call.

| id  | behavior                                                                                | traces   | kind    | state   | test                                                                              |
| --- | --------------------------------------------------------------------------------------- | -------- | ------- | ------- | --------------------------------------------------------------------------------- |
| A1  | A fresh chain returns the default policy from current()                                 | AC US1-1 | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`                  |
| A2  | A policy seeded into the datasource is served by StopPolicyProvider.current(NoParams()) | AC US1-2 | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`                  |
| A3  | update(policy) then current() returns exactly the policy written                        | AC US2-1 | example | DONE    | `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`         |
| A4  | reset() restores the documented default through the whole chain                         | AC US2-2 | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`                  |
| A5  | The provider serves reads through the datasource seam                    | AC US3-1 | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`                  |
| A6  | getCurrent with an unknown id raises StateError (no silent substitution)                | AC US3-2 | example | DONE    | `test/data/repositories/stop_policy/stop_policy_repository_impl_test.dart`        |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/stop_policy/stop_policy.dart`

| id  | behavior                                                                 | traces          | kind    | state   | test                                                                      |
| --- | ------------------------------------------------------------------------ | --------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U1  | StopPolicy.defaultPolicy carries the documented values (100/0/5/true)    | FR-001, SC-002  | example | DONE    | `test/domain/entities/stop_policy/stop_policy_test.dart`                  |
| U2  | Value equality across all five fields                                    | FR-001          | example | DONE    | `test/domain/entities/stop_policy/stop_policy_test.dart`                  |
| U3  | Equal instances have equal hashCodes                                     | FR-001          | example | DONE    | `test/domain/entities/stop_policy/stop_policy_test.dart`                  |

### `lib/src/data/datasources/stop_policy/` (interface + mock)

| id  | behavior                                                                 | traces          | kind    | state   | test                                                                      |
| --- | ------------------------------------------------------------------------ | --------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U4  | Mock implements the datasource interface (compile parity, issues #27/#28)| FR-002          | example | BASELINE | `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` |
| U5  | A fresh mock's current() returns StopPolicy.defaultPolicy                | FR-003          | example | DONE    | `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` |
| U6  | update fully replaces (changed id makes the old id unreachable)          | FR-003, edge-2  | example | DONE    | `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` |
| U7  | reset() on the mock restores the default                                 | FR-003          | example | DONE    | `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` |

### `lib/src/data/repositories/stop_policy_repository_impl.dart`

| id  | behavior                                                                 | traces          | kind    | state   | test                                                                      |
| --- | ------------------------------------------------------------------------ | --------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U8  | RepositoryImpl implements StopPolicyRepository (compile parity)          | FR-004          | example | DONE    | `test/data/repositories/stop_policy/stop_policy_repository_impl_test.dart`|
| U9  | getCurrent/update/reset delegate to the datasource                       | FR-004          | example | DONE    | `test/data/repositories/stop_policy/stop_policy_repository_impl_test.dart`|

### `lib/src/data/providers/stop_policy/stop_policy_provider.dart`

| id  | behavior                                                                 | traces          | kind    | state   | test                                                                      |
| --- | ------------------------------------------------------------------------ | --------------- | ------- | ------- | ------------------------------------------------------------------------- |
| U10 | Provider implements StopPolicyService (compile parity)                   | FR-005          | example | BASELINE | `test/data/providers/stop_policy/stop_policy_provider_test.dart`          |
| U11 | Parameterless StopPolicyProvider() keeps compiling (default wiring)      | FR-006          | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`          |
| U12 | defaultPolicy(NoParams) returns the canonical constant                   | FR-005          | example | DONE    | `test/data/providers/stop_policy/stop_policy_provider_test.dart`          |

## Invariants and edge cases still to place

- Single source of truth for defaults: mock seed, mock reset target, and
  provider defaultPolicy must all reference `StopPolicy.defaultPolicy` — pinned
  by U1/U5/U7/U12 asserting the same values.
- Wrong-id update: full replace means `getCurrent(oldId)` must raise
  `StateError` afterwards — covered by U6 + A6.

## Out of scope

- Stop-condition enforcement (turn-count comparison, typed outcome emission):
  engine-loop feature (specs 002/046), not the datasource pair.
- Hive/remote-backed datasource: interface contract only; mock is the
  reference implementation.
- Persisting multiple named policies simultaneously: the value object is a
  single instance; multi-policy stores are a future backend concern.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (corroboration only, never a gate)
- Mutation (changed files): no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
