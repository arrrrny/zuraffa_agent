# Tasks: ArtifactProvider.list NoParams override fix

**Branch**: `011-artifact-provider-noparams-list` | **Date**: 2026-08-24 | **Plan**: [plan.md](./plan.md)

## T1 — Create directory layout

- [x] T1.1 `mkdir -p lib/src/domain/services`
- [x] T1.2 `mkdir -p lib/src/data/providers/artifact`
- [x] T1.3 `mkdir -p test/data/providers/artifact`

## T2 — Hand-curated service interface

- [x] T2.1 Write `lib/src/domain/services/artifact_service.dart` declaring `abstract class ArtifactService` with `Future<List<ArtifactRef>> list(NoParams params)` and `int thresholdBytes(NoParams params)`.
- [x] T2.2 Header comment: `// HAND-CURATED — see issue arrrrny/zuraffa_agent#11 — zfa generator does not yet ship a consistent ArtifactService/ArtifactProvider pair; this file is the canonical source until it does.` and imports `package:zuraffa/zuraffa.dart` (for `NoParams`) and `../entities/artifact_ref/artifact_ref.dart`.
- [x] T2.3 Run `dart analyze lib/src/domain/services/artifact_service.dart` — must report 0 issues.

## T3 — Hand-curated provider stub

- [x] T3.1 Write `lib/src/data/providers/artifact/artifact_provider.dart` declaring `class ArtifactProvider implements ArtifactService`.
- [x] T3.2 Both methods (`list`, `thresholdBytes`) MUST declare the exact `NoParams params` parameter and MUST be decorated `@override`.
- [x] T3.3 Bodies are `async => throw UnimplementedError('Implement ArtifactProvider.<method>')` (for `list`) and `=> throw UnimplementedError(...)` (for `thresholdBytes`).
- [x] T3.4 Header comment block identical in spirit to T2.2.
- [x] T3.5 Run `dart analyze lib/src/data/providers/artifact/artifact_provider.dart` — must report 0 issues including no `invalid_override`.

## T4 — Regression test for the NoParams override

- [x] T4.1 Write `test/data/providers/artifact/artifact_provider_test.dart` with two tests:
  - `test('ArtifactProvider is an ArtifactService', () { expect(ArtifactProvider(), isA<ArtifactService>()); });`
  - `test('ArtifactProvider.list throws UnimplementedError on NoParams()', () async { await expectLater(ArtifactProvider().list(NoParams()), throwsA(isA<UnimplementedError>())); });`
  - `test('ArtifactProvider.thresholdBytes throws UnimplementedError on NoParams()', () { expect(() => ArtifactProvider().thresholdBytes(NoParams()), throwsA(isA<UnimplementedError>())); });`
- [x] T4.2 `dart test test/data/providers/artifact/artifact_provider_test.dart` — must pass all 3 tests.

## T5 — Repo-wide gate

- [x] T5.1 `dart pub get` — succeeds.
- [x] T5.2 `dart analyze --fatal-infos` — exits 0, no new warnings.
- [x] T5.3 `dart test` — all pre-existing 129 tests still pass + 3 new ones = ≥132 tests passing.

## T6 — Commit + PR + merge + pull + re-test

- [ ] T6.1 `git add -A && git commit -m "fix(artifact-provider): hand-curate NoParams signatures for list/thresholdBytes (closes #11, closes #12)"`
- [ ] T6.2 `git push -u origin 011-artifact-provider-noparams-list`
- [ ] T6.3 `gh pr create --base master --head 011-artifact-provider-noparams-list --title "fix(artifact-provider): NoParams override for list/thresholdBytes" --body "..." --label zfa-bug`
- [ ] T6.4 Wait for CI green (or verify locally with `dart analyze --fatal-infos && dart test`).
- [ ] T6.5 `gh pr merge <PR#> --squash --delete-branch`
- [ ] T6.6 Switch back to master worktree, `git pull --ff-only origin master`, `dart pub get`, `dart analyze --fatal-infos`, `dart test` — all green.
- [ ] T6.7 Close any remaining open issue links; update worklog with PR URL.

## T7 — Worklog & summary

- [ ] T7.1 Append `/home/z/my-project/worklog.md` section for issue #11 with: PR URL, merge commit SHA, worktree path, files added, test count delta.
