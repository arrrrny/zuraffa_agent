# Test List: 011-artifact-provider-noparams-list

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | its `list` method declares `Future<List<ArtifactRef>> list(NoParams params)` and `dart analyze` reports no `invalid_override` error. | AC-1 | PENDING |
| A2 | the override is `int thresholdBytes(NoParams params)` (shared root cause with issue #12; the hand-curated file resolves both — each issue still gets its own PR per the per-issue worktree rule). [AC-2] | AC-2 | PENDING |
| A3 | the parameterless-method round-trip test (`list(NoParams())` and `thresholdBytes(NoParams())`) passes against the in-memory stub provider. [AC-3] | AC-3 | PENDING |
| A4 | the cloned files pass `dart analyze` after only the entity-type swap. [AC-4] | AC-4 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `lib/src/domain/services/artifact_service.dart` MUST declare `abstract class ArtifactService` with method signatures `Future<List<ArtifactRef>> list(NoParams params)` and `int thresholdBytes(NoParams params)`. | FR-001 | PENDING |
| U2 | `lib/src/data/providers/artifact/artifact_provider.dart` MUST declare `class ArtifactProvider implements ArtifactService` whose overrides of `list` and `thresholdBytes` carry the exact same `NoParams params` parameter as the service. | FR-002 | PENDING |
| U3 | The provider methods MUST be stubbed with `throw UnimplementedError()` bodies (matching the zfa-generated stub convention for `--di mock`/`--provider` outputs) so the file is analyzable without forcing real I/O. | FR-003 | PENDING |
| U4 | `dart analyze --fatal-infos` MUST report zero issues on the two new files and zero new issues on `lib` as a whole. | FR-004 | PENDING |
| U5 | `dart test` MUST continue to pass all 129 pre-existing tests AND a new test file at `test/data/providers/artifact_provider_test.dart` that exercises the NoParams round-trip and asserts the override relationship (`ArtifactProvider` is an `ArtifactService`). | FR-005 | PENDING |
| U6 | A short comment at the top of each new file MUST explain that the file is a hand-curated placeholder for the zfa-generated equivalent, and link back to issue #11, so the next contributor understands why the file exists before the zfa tool ships the matching fix. | FR-006 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

