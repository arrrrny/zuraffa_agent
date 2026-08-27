# Implementation Plan: ArtifactProvider.list NoParams override fix

**Branch**: `011-artifact-provider-noparams-list` | **Date**: 2026-08-24 (refined 2026-08-27) | **Spec**: [spec.md](./spec.md)

> **Cycle amendment (2026-08-27)**: the hand-curated `ArtifactService` +
> `ArtifactProvider` pair and the contract test landed via PR #32 (squash
> 861362d) before this SDD cycle ran. This cycle therefore (a) unblocks the
> build off-machine by removing the duplicate `dependency_overrides` key in
> pubspec.yaml (the stray dev-machine path override — same fix as the
> spec-007 stack), (b) completes the spec-kit artifacts (this plan, tasks,
> TDD test-list/cycle-log/verification), and (c) performs a fresh TDD
> verification: green re-run of the contract suite, `dart analyze` gates on
> the pair, and deliberate-mutant checks including re-introducing the exact
> #11 bug shape. No re-implementation: the merged files ARE the deliverable
> this spec documents.

**Input**: Feature specification from `/specs/011-artifact-provider-noparams-list/spec.md`

## Summary

Add a hand-curated `ArtifactService` interface (`lib/src/domain/services/artifact_service.dart`) and `ArtifactProvider` class (`lib/src/data/providers/artifact/artifact_provider.dart`) whose parameterless methods (`list`, `thresholdBytes`) declare `NoParams params` consistently across the service and its implementing provider. The bodies are `UnimplementedError` stubs, matching the zfa-generated stub convention, so the repo compiles green and downstream zfa-bug issues can clone this pair as a template.

## Technical Context

**Language/Version**: Dart 3.13.1 (stable), SDK constraint `^3.11.0` per `pubspec.yaml`.

**Primary Dependencies**: `zuraffa: 6.0.0` (provides `NoParams`, `Loggable`, `FailureHandler`, `UseCase`, `QueryParams`, `CancelToken`, `GetIt`, etc.); `zorphy: 2.3.0` and `zorphy_annotation: 2.3.0` (provide the `@Zorphy` codegen for `ArtifactRef`).

**Storage**: None — these are in-memory interface and stub class declarations.

**Testing**: `dart test` (package:test). Existing test suite at `test/` (129 tests passing on master).

**Target Platform**: Linux x64 (build box), but the package itself is platform-agnostic Dart.

**Project Type**: Library package (`zuraffa_agent`) consumed by an agent runtime.

**Performance Goals**: N/A — these are zero-runtime-cost declarations; the bodies throw.

**Constraints**: MUST NOT import `dart:io` (CI runtime purity gate). MUST NOT introduce a new analyzer warning. MUST NOT regress the 129 pre-existing tests.

**Scale/Scope**: 2 new `.dart` files (~30 lines each), 1 new test file (~40 lines), 1 new directory (`lib/src/data/providers/artifact/`), 1 new directory (`lib/src/domain/services/`).

## Constitution Check

Re-check against `specs/003-tools-and-mcp/spec.md` §Key Entities (lists `ToolResult` and `ArtifactRef` as the spec-003 data model) — the new files implement part of spec-003's data layer (artifact provider/service). The hand-curated implementation does NOT violate spec-003's intent; it surfaces the layer ahead of the upstream zfa fix.

Runtime purity gate (`.github/workflows/pipeline.yml`): the new files do not import `dart:io`. ✓

Attribution gate: no ported source — original hand-curated code. ✓

## Project Structure

### Documentation (this feature)

```text
specs/011-artifact-provider-noparams-list/
├── spec.md                # /skill:speckit-specify output
├── plan.md                # This file (/skill:speckit-plan output)
├── tasks.md               # /skill:speckit-tasks output (next phase)
└── checklists/
    └── requirements.md    # /skill:speckit-specify quality checklist
```

### Source Code (repository root)

```text
lib/src/
├── domain/
│   ├── services/                      # NEW directory
│   │   └── artifact_service.dart      # NEW — abstract interface
│   └── entities/artifact_ref/        # exists
└── data/
    └── providers/                    # NEW directory
        └── artifact/
            └── artifact_provider.dart  # NEW — concrete provider

test/
└── data/
    └── providers/
        └── artifact/
            └── artifact_provider_test.dart  # NEW — NoParams round-trip test
```

## Phase 0 — Research (already complete, summarized)

**Q1: Does `package:zuraffa/zuraffa.dart` actually export `NoParams`?**
Yes — the existing `lib/src/domain/usecases/usage_ledger_entry/update_usage_ledger_entry_usecase.dart` references it through that import.

**Q2: Is `ArtifactRef` already in the export graph?**
Yes — `lib/src/domain/entities/artifact_ref/artifact_ref.dart` is a Zorphy value object with `kind`, `id`, optional `uri`. Its mock data file already lives at `lib/src/data/mock/artifact_ref_mock_data.dart`, confirming the entity is wired through.

**Q3: What does the zfa-generated stub convention look like?**
See `lib/src/data/datasources/turn_record/turn_record_remote_datasource.dart` — `class XRemoteDataSource with Loggable, FailureHandler implements XDataSource { ... throw UnimplementedError('Implement remote ...') }` and a top-of-file `// GENERATED - DO NOT EDIT` comment. We mirror the same shape for `ArtifactProvider`, with the header changed to `// HAND-CURATED — see issue arrrrny/zuraffa_agent#11` (NOT `// GENERATED` — we must not pretend the file came from zfa).

## Phase 1 — Design

### Data Model

The data surface for `ArtifactProvider`/`ArtifactService` is exactly two methods:

| Method | Service signature | Provider override signature | Returns |
|--------|-------------------|------------------------------|---------|
| `list` | `Future<List<ArtifactRef>> list(NoParams params)` | identical | `Future<List<ArtifactRef>>` |
| `thresholdBytes` | `int thresholdBytes(NoParams params)` | identical | `int` |

The `params` argument is ignored by the stub bodies. This is intentional: the parameter exists ONLY to satisfy the override contract.

### Contracts

```dart
// lib/src/domain/services/artifact_service.dart
abstract class ArtifactService {
  Future<List<ArtifactRef>> list(NoParams params);
  int thresholdBytes(NoParams params);
}

// lib/src/data/providers/artifact/artifact_provider.dart
class ArtifactProvider implements ArtifactService {
  const ArtifactProvider();
  @override
  Future<List<ArtifactRef>> list(NoParams params) async =>
      throw UnimplementedError('Implement ArtifactProvider.list');
  @override
  int thresholdBytes(NoParams params) =>
      throw UnimplementedError('Implement ArtifactProvider.thresholdBytes');
}
```

### Quickstart

```bash
cd /workspace/zuraffa_agent/.worktrees/011-artifact-provider-noparams-list
dart pub get
dart analyze --fatal-infos
dart test
```

## Phase 2 — Tasks (next phase, written by `/skill:speckit-tasks`)

See `tasks.md`.
