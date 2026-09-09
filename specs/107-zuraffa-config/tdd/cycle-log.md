# TDD Cycle Log: ZuraffaConfig runtime configuration (spec 107)

Append-only record of the red-green-refactor cycles.

## Baseline

- **planned_at**: 2026-09-09, branch `107-zuraffa-config` (off post-#142 master)
- **suite**: 1223 passed, 0 failed, ~2 skipped
- **analyzer**: `No issues found!`
- **misfire protocol**: user-authorized report-and-continue (same as 105/106).

## Cycle 1 — the aggregate + typed validation (U1–U5)

### RED

```
$ dart test test/config/zuraffa_config_test.dart
  Failed to load "test/config/zuraffa_config_test.dart":
  Error: Target of URI doesn't exist: 'package:zuraffa_agent/src/config/zuraffa_config.dart'
  Error: Undefined class 'ZuraffaConfig'.
```

(Compile-error red per the playbook; fixtures then aligned to the real
entity constructor signatures.)

### GREEN

`ZuraffaConfig` + sealed `ConfigIssue` family (missing / outOfRange /
incompatible) with deterministic validate() order. One in-cycle fix: the
private list-equality helper name.

```
$ dart test test/config/zuraffa_config_test.dart → 5 passed; analyze clean
```

## Cycle 2 — YAML + env loaders (U6–U10)

### RED

```
$ dart test test/config/zuraffa_config_loader_test.dart
  Failed to load ... zuraffa_config_loader.dart doesn't exist
```

### GREEN

`fromYaml` (spec-104-style diagnostics; unknown keys ignored) and `fromEnv`
(injected map, `ZFA_*` names, numeric parse errors naming the variable).
Test-mechanics fix mid-cycle: the typed-error predicates matched
`e.message` (which omits the parameter name) — corrected to `e.toString()`.

```
$ dart test test/config/zuraffa_config_loader_test.dart → 5 passed
```

## Cycle 3 — SecretResolver interface + stub (U11)

### RED

Compile-error red (interface absent); test written first.

### GREEN

`SecretResolver` (fromEnv / fromFile / fromVault) + `NullSecretResolver`
(absence without throwing). `+1 passed`.

## Cycle 4 — MissionRunner fail-fast gate (U12–U14)

### RED

```
$ dart test test/engine/mission_runner_config_gate_test.dart
  Error: No named parameter with the name 'config'.   (×3)
```

### GREEN

Optional `config` on `MissionRunner`; `run()` throws `StateError` listing
every issue before the first event; valid/no-config paths unchanged.

```
$ dart test  → 1238 passed / 0 failed; dart analyze → No issues found!
```

## Cycle 5 — README contract + A1/A3 (SC-001/SC-005)

### RED

A1/A3 test added first: README lacked the section (`expect(fence,
greaterThanOrEqualTo(0))` fails).

### GREEN

README "Configuring the engine" section with contract + example document;
the test parses the README's own ```yaml block through the loader and
validates clean.

```
$ dart test test/config/ → 12 passed; full suite 1238/0; analyzer clean
```

## Audit mutant (post-cycle)

```
MUTANT: startup gate disabled (config != null && false)
$ dart test ... --plain-name "U12"
U12: an invalid configuration throws before any event or call [E]
  Expected: throws satisfies function
    Actual: <Instance of 'Future<MissionResult>'>
```

Killed by U12; restored exactly; gate tests re-green; analyzer clean.
