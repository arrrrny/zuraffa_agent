# ZFA Misfire #001 — `zfa initialize` cannot bootstrap an existing repo (no in-place mode, no pure-Dart initialize)

**Date**: 2026-08-18 · **Stage**: implement (T001) · **Constitution**: I (zfa-CLI-only), II (stop on first misfire), III (escalate upstream & wait)

## Command run

```bash
cd /Users/ahmettok/Developer/zuraffa_agent   # repo root; git-tracked project, NO pubspec.yaml yet
zfa initialize
```

## Expected

`zfa initialize` wires zuraffa dependencies into `pubspec.yaml` and scaffolds a test entity **in the current project root**. Per `zfa initialize --help`: *"Initialize a project for Zuraffa: wire dependencies + scaffold a test entity"* — no precondition that a pubspec.yaml must already exist, and no hint that a pure-Dart package is unsupported.

## What happened

```
❌ No pubspec.yaml found in current directory.
   Run `zfa setup <name>` to create a new app, or cd to a project root.
exit=64
```

`zfa initialize` requires a **pre-existing** `pubspec.yaml` — but there is no zfa command that creates one **in-place** for an existing repository:

- `zfa setup <name> --dart` creates a **new subdirectory** (`dart create -t package <name>`) — cannot be used in an existing repo root (`zfa setup . --dart` → `❌ Invalid app name: "."`).
- `zfa initialize` has no `--dart`/project-type awareness at all (wires the Flutter set: `zuraffa_flutter`, build_runner, etc.).

## Root cause (zuraffa side)

1. `initialize` and `setup` are disjoint: `setup` can create but only out-of-place; `initialize` can wire in-place but only into an existing pubspec.
2. No pure-Dart mode on `initialize` (always wires Flutter deps — wrong for a pure engine package like zuraffa_agent).

## Fix (zuraffa enhancement, upstream)

- `zfa initialize --dart` (or `--pure`): detect no-pubspec → run `dart create -t package .` **in the current directory** (or synthesize a minimal pubspec.yaml) → wire the **pure-Dart** dependency set → continue entity scaffold as today.
- Accept `zfa setup . --dart` as in-place alias.

## Prevention

- The gap is product-level, not process-level: until fixed, NO workflow may pre-create `pubspec.yaml` by hand to unblock (that would violate constitution I). The pipeline stays halted; resume only after the zuraffa fix lands (constitution III).

## Process misfire (secondary — fixed in-repo)

The implement agent stopped correctly (no workarounds, no hand-written pubspec) but did NOT write this misfire.md; `gate_impl` caught the halt instead. Prompt now mandates writing misfire.md as the FIRST action on any zfa failure.
