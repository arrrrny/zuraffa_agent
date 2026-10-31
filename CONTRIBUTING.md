# Contributing to zuraffa_agent

Thanks for contributing! This guide covers the basics of getting a change in,
and — importantly for this repo — which files under `.zfa/` and `.workflow/`
are source you should commit versus generated artifacts you never commit.

## Getting started

This is a pure Dart package (Dart SDK `^3.8.0`, see `pubspec.yaml`):

```bash
git clone https://github.com/arrrrny/zuraffa_agent.git
cd zuraffa_agent
git checkout -b fix/<issue>-<short-slug>
dart pub get
```

> If `pubspec.yaml` carries a `dependency_overrides:` section with `path:`
> entries, those point at local copies that only exist on the maintainer's
> machine — remove them before `pub get` on a fresh clone.

## Tests, format, analyze

- Always run the suite with a **concurrency cap** — an uncapped suite can
  saturate the host: `dart test -j 2`.
- `dart format .` must produce no diffs.
- `dart analyze` must be clean (the pipeline gate runs
  `dart analyze --fatal-infos`).

## `.zfa/` and `.workflow/`: source vs generated

The agent engine and the spec-driven delivery pipeline write runtime state
into `.zfa/` and `.workflow/`. Only the deliberately-committed parts below
belong in version control; everything listed as **generated** is ignored via
`.gitignore` and must never be committed.

| Path | Class | What it is |
|---|---|---|
| `.zfa/context.json` | **Source — commit** | Checked-in agent configuration (domain root, generated/manual zones, workflow commands). |
| `.zfa/corpus/` | **Source — commit** | Eval-harness baseline corpus (golden inputs the evals run against). |
| `.zfa/manifests/` | **Source — commit** | Corpus manifest describing what the eval baseline contains. |
| `.zfa/receipts/` | **Kept — commit** | `proof.v1` receipts: reproducibility records for executed commands (command, repro, file hashes). Retained deliberately for traceability. |
| `.zfa/plans/plan_<id>.json` | **Kept — commit** | Individual plan snapshots retained as records. |
| `.zfa/plans/last_run_*` | **Generated — never commit** | Snapshot of the last executed plan per capability; rewritten on every run. |
| `.zfa/runs/` | **Generated — never commit** | Per-run records (turns, tool invocations, usage ledger), including generated file contents. |
| `.workflow/WORKFLOW.md` | **Source — commit** | The spec-driven delivery workflow documentation. |
| `.workflow/state/` | **Generated — never commit** | Live pipeline state for the current run (stage logs, `stages.done`, review notes). |
| `.workflow/state-archive/` | **Generated — never commit** | Archived pipeline state from completed runs. |

Rule of thumb: if the file is produced by an agent run or a pipeline stage
(`zfa` run output, `scripts/pipeline.sh` state), it is generated. If a fresh
clone needs the file for the tool, evals or config to work, it is source.

### If generated artifacts end up committed anyway

Untrack them without deleting the local copies, and make sure the pattern is
in `.gitignore` first:

```bash
git rm --cached -r .zfa/runs/
git rm --cached .zfa/plans/last_run_*
git rm --cached -r .workflow/state-archive/
git commit -m "chore: untrack generated .zfa/.workflow artifacts"
```

## Pull requests

- One PR per issue, kept tightly scoped to what the issue describes.
- Reference the issue with `Closes #<n>` in the PR body.
- Tests green (`dart test -j 2`), `dart format .` and `dart analyze` clean
  before you push.
- PRs are reviewed by the forklift review pool — never merge a PR yourself,
  even if it looks finished (see `AGENTS.md`).
