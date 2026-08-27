# Test List: ArtifactProvider.list NoParams override fix

---
feature: 011-artifact-provider-noparams-list
loop: contract-first (implementation landed via PR #32 before this cycle; this list documents the pinned behaviors and drives the fresh verification + mutation checks)
profile: .specify/memory/tdd-profile.md
spec_criteria: 4 # acceptance criteria AC-1..AC-4 in spec.md
planned_at: a1fb738
updated_at: a1fb738
suite_baseline: red # master baseline: +379 passed / 8 pre-existing loading failures (unrelated specs); green criterion = contract suite green AND zero new full-suite failures/analyze issues vs master
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| A1  | The pair compiles clean: `dart analyze` reports no `invalid_override` on `artifact_service.dart` + `artifact_provider.dart` | AC-1, AC-2, FR-004 | gate | DONE | `dart analyze <pair>` → No issues found (re-run this cycle) |
| A2  | The NoParams round-trip: `list(NoParams())` / `thresholdBytes(NoParams())` execute against the stub provider | AC-3, FR-005 | example | DONE | `artifact_provider_test.dart` (throws-stub contract) |
| A3  | Full-suite non-regression: master baseline preserved (+379/-8; 162 analyze issues all pre-existing) | FR-004, FR-005 | gate | DONE | full `dart test` + `dart analyze` this branch |

## Inner loop: unit behaviors

### `lib/src/data/providers/artifact/artifact_provider.dart` + `lib/src/domain/services/artifact_service.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U1  | `ArtifactProvider implements ArtifactService` — the override relationship holds | AC-1, FR-002 | example | DONE | `artifact_provider_test.dart::is an ArtifactService` |
| U2  | `list(NoParams())` on the stub throws `UnimplementedError` (zfa stub convention, FR-003) | AC-3, FR-003 | example | DONE | `artifact_provider_test.dart::list throws` |
| U3  | `thresholdBytes(NoParams())` on the stub throws `UnimplementedError` | AC-2, AC-3, FR-003 | example | DONE | `artifact_provider_test.dart::thresholdBytes throws` |
| U4  | Compile-time guard: `NoParams` remains the declared parameter type (removal reintroduces #11) | AC-1, FR-001/FR-002 | example | DONE | `artifact_provider_test.dart::compile-time guard` |
| U5  | `ArtifactRef` stays wired through the package graph (entity export non-regression) | FR-006 context | example | DONE | `artifact_provider_test.dart::ArtifactRef constructible` |

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| stub bodies | `list` returns `<ArtifactRef>[]` instead of throwing | U2 (+4 -1) |
| parameter list | drop `NoParams params` from `list` — the exact issue-#11 shape | compile gate: `invalid_override` reappears (A1) |
