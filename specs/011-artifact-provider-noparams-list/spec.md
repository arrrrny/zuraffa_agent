# Feature Specification: ArtifactProvider.list NoParams override fix

**Feature Branch**: `011-artifact-provider-noparams-list`

**Created**: 2026-08-24

**Status**: Draft

**Input**: Bug arrrrny/zuraffa_agent#11 — `zfa make`-generated `ArtifactProvider.list` declares `Future<List<ArtifactRef>> Function()` while the generated `ArtifactService` interface declares `Future<List<ArtifactRef>> Function(NoParams)`. The two generated artifacts are inconsistent and `lib` does not compile. This spec defines the consistent, hand-curated replacement that lives in the consuming repo so the build gate is green even before the upstream zfa generator ships the matching fix.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Repository compiles with consistent service/provider pair (Priority: P1)

As the build CI, I see `dart analyze --fatal-infos` succeed on `lib/src/data/providers/artifact/artifact_provider.dart` and `lib/src/domain/services/artifact_service.dart` because the provider overrides every service method with the exact same parameter list, including the `NoParams` argument that the service declares for parameterless methods.

**Why this priority**: The repository does not compile today as soon as a `zfa make ArtifactProvider`-shaped provider is checked in. Restoring the green build gate is the first thing every downstream user (developer, CI, release script) needs.

**Independent Test**: Run `dart analyze --fatal-infos lib/src/data/providers/artifact/artifact_provider.dart lib/src/domain/services/artifact_service.dart` and assert exit code 0. No other file needs to be touched for this assertion.

**Acceptance Scenarios**:

1. **Given** an `ArtifactService` interface declaring `Future<List<ArtifactRef>> list(NoParams params)`, **When** `ArtifactProvider` is generated to `implement ArtifactService`, **Then** its `list` method declares `Future<List<ArtifactRef>> list(NoParams params)` and `dart analyze` reports no `invalid_override` error.
2. **Given** the parameterless service method `int thresholdBytes(NoParams params)`, **When** `ArtifactProvider` overrides it, **Then** the override is `int thresholdBytes(NoParams params)` (this is the shared root cause with issue #12; the fix is identical and the same hand-curated file closes both issues, but each issue gets its own PR per the per-issue worktree rule).
3. **Given** any future contributor running `dart test`, **Then** the parameterless-method round-trip test (`list(NoParams())` and `thresholdBytes(NoParams())`) passes against the in-memory stub provider.

### User Story 2 - Pattern is reproducible for other parameterless services (Priority: P2)

As the next agent fixing a sibling zfa-bug (e.g. #12, #25, #27, #29), I copy the `ArtifactService` + `ArtifactProvider` pair as a template, swap the entity name, and the resulting files compile on the first try without re-deriving the NoParams rule from scratch.

**Why this priority**: There are 21 open `zfa-bug` issues and at least 6 of them are the same shape (`NoParams` parameter mismatch on a parameterless service method). A correct, well-documented reference pair multiplies the value of this single PR.

**Independent Test**: Open `artifact_provider.dart`, mechanically clone it to `repetition_tracker_provider.dart`, change `ArtifactRef` to the new entity, and run `dart analyze` on the new file — it must pass without further edits.

**Acceptance Scenarios**:

1. **Given** the merged `ArtifactService` / `ArtifactProvider` files, **When** an agent clones them for the next parameterless-service fix, **Then** the cloned files pass `dart analyze` after only the entity-type swap.

### Edge Cases

- What happens when a service method has *real* parameters (e.g. `Future<ArtifactRef> read(ReadParams params)`)? — The provider must still match the service signature exactly; the NoParams rule only applies to truly parameterless methods. The hand-curated provider demonstrates this by also overriding any parameter-bearing method with the matching `*Params` type.
- What happens when a parameterless method is invoked from a use case? — The use case must construct `NoParams()` and pass it through; the provider must accept and (for the stub) ignore it.
- What happens if a future zfa generator emits the consistent signatures? — The hand-curated files become redundant and can be regenerated; until then they are the source of truth committed to the repo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `lib/src/domain/services/artifact_service.dart` MUST declare `abstract class ArtifactService` with method signatures `Future<List<ArtifactRef>> list(NoParams params)` and `int thresholdBytes(NoParams params)`.
- **FR-002**: `lib/src/data/providers/artifact/artifact_provider.dart` MUST declare `class ArtifactProvider implements ArtifactService` whose overrides of `list` and `thresholdBytes` carry the exact same `NoParams params` parameter as the service.
- **FR-003**: The provider methods MUST be stubbed with `throw UnimplementedError()` bodies (matching the zfa-generated stub convention for `--di mock`/`--provider` outputs) so the file is analyzable without forcing real I/O.
- **FR-004**: `dart analyze --fatal-infos` MUST report zero issues on the two new files and zero new issues on `lib` as a whole.
- **FR-005**: `dart test` MUST continue to pass all 129 pre-existing tests AND a new test file at `test/data/providers/artifact_provider_test.dart` that exercises the NoParams round-trip and asserts the override relationship (`ArtifactProvider` is an `ArtifactService`).
- **FR-006**: A short comment at the top of each new file MUST explain that the file is a hand-curated placeholder for the zfa-generated equivalent, and link back to issue #11, so the next contributor understands why the file exists before the zfa tool ships the matching fix.

### Key Entities

- **ArtifactService** (abstract interface): `list(NoParams)` and `thresholdBytes(NoParams)` — the parameterless service surface.
- **ArtifactProvider** (concrete class): implements `ArtifactService` with matching NoParams signatures; default bodies throw `UnimplementedError`.
- **NoParams**: the existing `package:zuraffa/zuraffa.dart`-exported marker type for parameterless use-case invocations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart analyze --fatal-infos` exits 0 on the worktree.
- **SC-002**: `dart test` exits 0 with ≥ 130 tests passing (the 129 pre-existing + at least one new NoParams override test).
- **SC-003**: No `invalid_override` analyzer code is reported against `ArtifactProvider` or any sibling file.
- **SC-004**: The PR is merged to `master` (squash) and the merged commit, when checked out and re-tested, is green.

## Assumptions

- The `NoParams` type is exported by `package:zuraffa/zuraffa.dart` (verified by reading the existing `lib/src/domain/usecases/*` files that import it).
- `ArtifactRef` already exists at `lib/src/domain/entities/artifact_ref/artifact_ref.dart` and is exported through `lib/zuraffa_agent.dart` (verified — it is a Zorphy value object with `kind`, `id`, optional `uri`).
- The CI gate (`.github/workflows/pipeline.yml`) runs `dart analyze --fatal-infos` + `dart test` + the runtime purity gate; this PR must not regress any of those.
- Issue #12 (`thresholdBytes` override) shares the same root cause and the same fix surface. The hand-curated file shipped here resolves both, but per the per-issue worktree rule each issue still gets its own PR.
