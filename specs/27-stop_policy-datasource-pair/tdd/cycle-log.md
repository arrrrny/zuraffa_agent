# Cycle Log: StopPolicy datasource + mock pair

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 544 passed, 0 failed (post spec-25)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged)
- commit: `58c9062`
- recorded: cycle 0, before any spec-27 change

## Cycle 1: U1..U3 entity default constant

- test: `test/domain/entities/stop_policy/stop_policy_test.dart` (new, 3 tests)
- red: `dart test test/domain/entities/stop_policy/stop_policy_test.dart`
  -> compile error: `Member not found: 'defaultPolicy'` (1 load failure)
- green: `static const StopPolicy defaultPolicy` added to the entity — single source of truth for the documented default (100 / Duration.zero / 5 / true / 'default'). Suite -> 547 passed
- refactor: none — one constant
- commit: entity test (red), `5c1d795` (green)

## Cycle 2: A3 + U4..U7 datasource pair

- test: `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` (rewritten: 8 pre-refinement tests superseded — 3 `UnimplementedError` stub assertions + 5 entity-surface tests whose semantics are covered by the new entity test file: Duration field, int fields, enabled default, five-field equality, Duration.zero wall-clock; kept the `isA` compile-parity check; 4 behavior tests added)
- red: `dart test test/data/datasources/stop_policy/`
  -> compile error: `The method 'update' isn't defined for the type 'StopPolicyMockDatasource'`
- green: interface gained `update(StopPolicy)` (full-replace write returning the stored value); mock implemented in memory seeded with `StopPolicy.defaultPolicy`; `reset` restores the default. Suite -> 549 passed (8 old tests replaced by 4)
- refactor: none
- commit: datasource test (red), `3e759c2` (green)

## Cycle 3: A6 + U8..U9 repository over the datasource

- test: `test/data/repositories/stop_policy_repository_impl_test.dart` (new, 6 tests)
- red: compile error — `No such file or directory ... stop_policy_repository_impl.dart` / `Method not found: 'StopPolicyRepositoryImpl'`
- green: `lib/src/data/repositories/stop_policy_repository_impl.dart` implementing the domain repository by delegating to `StopPolicyDatasource`; `getCurrent(id)` raises `StateError` on id mismatch. Two corrections during green:
  1. **Import depth**: the first version used `../../../domain/...` from `lib/src/data/repositories/` — one level too deep, producing exactly the `uri_does_not_exist` error class from issue #27. Fixed to `../../domain/...` (analyze 14 -> 5 issues).
  2. **Fixture correction**: U9's second expectation originally asserted `getCurrent('default')` returns a non-strict value after the store was replaced with 'strict' — contradicting the spec's own edge-2 semantics. Corrected to expect `StateError`.
  Suite -> 549 passed
- refactor: none — pure delegation + one guard
- commit: repository test (red), `b54244b` (green, with the two corrections)

## Cycle 4: A1/A2/A4/A5 + U10..U12 provider chain

- test: `test/data/providers/stop_policy/stop_policy_provider_test.dart` (rewritten: 5 pre-refinement `UnimplementedError` stub assertions superseded; 7 behavior tests added)
- red: compile error — `No named parameter with the name 'repository'`; after the first implementation attempt, three behavior tests failed with `Bad state: No StopPolicy stored for id "default" (stored: "strict"/"relaxed")`
- **design correction (the decisive red)**: the initial provider delegated `current(NoParams)` to `repository.getCurrent(StopPolicy.defaultPolicy.id)` — a hardcoded id. The red tests proved an id-keyed delegation cannot serve an arbitrary active policy: the service surface is id-less by design (`NoParams`), so the provider must bind to the datasource's id-less `current()`. The repository remains the id-keyed domain-facing seam over the same datasource; both consume the datasource, which is exactly the task's wording ("how the service/repository consume it"). Spec FR-005/FR-006/SC-003/US3 and plan decision 3 amended in the same commit as the fix, with this entry as the record.
- green: provider consumes `StopPolicyDatasource` (constructor-injectable, parameterless default = fresh mock); `defaultPolicy` returns the canonical constant. Suite -> 551 passed
- refactor: none
- commit: provider test (red), `658a3d0` (green + spec/plan amendment)

## Notes and deviations

- Suite arithmetic: 544 (post-25) + 3 (entity) + 4-8 (datasource: 4 behavior tests replace 8 stub/surface tests, all 5 surface semantics retained in the entity file) + 6 (repository) + 7-5 (provider: 7 behavior tests replace 5 stub tests) = 551.
- `dart analyze` held at the 5 pre-existing issues across all cycles except the transient cycle-3 import-depth error (14 issues), fixed within the same green step.
- The cycle-4 design correction changed spec text mid-loop. The change is recorded here, in the amended spec/plan (same commit `658a3d0`), and flagged in verification.md as a LOW finding for reviewer attention — the red evidence for both the original and corrected designs is preserved in git history.
