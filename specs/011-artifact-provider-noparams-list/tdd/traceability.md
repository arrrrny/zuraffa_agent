# Traceability: 011-artifact-provider-noparams-list

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:fa6d1ff522cbe0a1a1cceaca20f31ee7567f7124c4b9690bc888eba26005e2e4
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** an `ArtifactService` interface declaring `Future<List<ArtifactRef>> list(NoParams params)`, **When** `ArtifactProvider` is generated to `implement ArtifactService`, **Then** its `list` method declares `Future<List<ArtifactRef>> list(NoParams params)` and `dart analyze` reports no `invalid_override` error. | A1 | automated |
| AC-2 | 27 | 2. **Given** the parameterless service method `int thresholdBytes(NoParams params)`, **When** `ArtifactProvider` overrides it, **Then** the override is `int thresholdBytes(NoParams params)` (shared root cause with issue #12; the hand-curated file resolves both — each issue still gets its own PR per the per-issue worktree rule). **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** any future contributor running `dart test`, **Then** the parameterless-method round-trip test (`list(NoParams())` and `thresholdBytes(NoParams())`) passes against the in-memory stub provider. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** the merged `ArtifactService` / `ArtifactProvider` files, **When** an agent clones them for the next parameterless-service fix, **Then** the cloned files pass `dart analyze` after only the entity-type swap. **[AC-4]** | A4 | automated |
| FR-001 | 55 | - **FR-001**: `lib/src/domain/services/artifact_service.dart` MUST declare `abstract class ArtifactService` with method signatures `Future<List<ArtifactRef>> list(NoParams params)` and `int thresholdBytes(NoParams params)`. | U1 | automated |
| FR-002 | 56 | - **FR-002**: `lib/src/data/providers/artifact/artifact_provider.dart` MUST declare `class ArtifactProvider implements ArtifactService` whose overrides of `list` and `thresholdBytes` carry the exact same `NoParams params` parameter as the service. | U2 | automated |
| FR-003 | 57 | - **FR-003**: The provider methods MUST be stubbed with `throw UnimplementedError()` bodies (matching the zfa-generated stub convention for `--di mock`/`--provider` outputs) so the file is analyzable without forcing real I/O. | U3 | automated |
| FR-004 | 58 | - **FR-004**: `dart analyze --fatal-infos` MUST report zero issues on the two new files and zero new issues on `lib` as a whole. | U4 | automated |
| FR-005 | 59 | - **FR-005**: `dart test` MUST continue to pass all 129 pre-existing tests AND a new test file at `test/data/providers/artifact_provider_test.dart` that exercises the NoParams round-trip and asserts the override relationship (`ArtifactProvider` is an `ArtifactService`). | U5 | automated |
| FR-006 | 60 | - **FR-006**: A short comment at the top of each new file MUST explain that the file is a hand-curated placeholder for the zfa-generated equivalent, and link back to issue #11, so the next contributor understands why the file exists before the zfa tool ships the matching fix. | U6 | automated |

