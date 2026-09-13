# Implementation Plan: `ZuraffaConfig` runtime configuration (issue #121)

**Branch**: `107-zuraffa-config` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

A `ZuraffaConfig` aggregate (six nullable sections) + typed `validate()` +
YAML/env loaders + a `SecretResolver` interface + a fail-fast gate in
`MissionRunner.run`. Sections are the existing value objects, carried
verbatim. Loaders live beside the value object, take injected inputs
(document string / environment map), and use the spec 104 loader-diagnostic
precedent. Runtime purity holds: no dart:io in any new lib file.

## Technical Context

Dart 3.x; deps: `package:yaml` (present) for the document loader; test +
mocktail present. Baseline: 1223 passed / 0 failed, analyzer clean at the
#142 merge. Constitution VII (no dart:io in new lib files), IX (plain-Dart
config aggregate per the spec 081/104 hand-curated precedent — recorded in
file headers), X (pristine analysis).

## Project Structure

```text
lib/src/config/
├── zuraffa_config.dart        # aggregate + ConfigIssue family + validate()
├── zuraffa_config_loader.dart # fromYaml / fromEnv (injected inputs)
└── secret_resolver.dart       # interface + null stub
test/config/
├── zuraffa_config_test.dart
├── zuraffa_config_loader_test.dart
└── secret_resolver_test.dart
test/engine/mission_runner_config_gate_test.dart
README.md  # "Configuring the engine" section (EDIT)
```

## Components

1. **`ZuraffaConfig`** — nullable sections: `providerConfig`, `agentSpec`,
   `engineLoop`, `mcpTransport`, `stopPolicy`, `compactionStrategy`;
   value equality; `validate()`.
2. **`ConfigIssue`** — sealed: `ConfigIssueMissing(section, requiredBy)`,
   `ConfigIssueOutOfRange(section, field, value, boundDescription)`,
   `ConfigIssueIncompatible(sectionA, sectionB, reason)`; all carry
   human-readable messages; value semantics.
3. **`validate()`** rules (cross-cutting, deterministic order):
   - outOfRange: `engineLoop.maxTurns <= 0`; `stopPolicy.enabled &&
     maxTurns <= 0`; `providerConfig.timeoutMs <= 0`;
     `stopPolicy.wallClockTimeout` negative.
   - missing: `engineLoop` configured ⇒ `providerConfig` required (the
     issue's example); `compactionStrategy`/`mcpTransport` configured ⇒
     nothing extra.
   - incompatible: `engineLoop.sessionId` ≠ `compactionStrategy.sessionId`.
4. **`ZuraffaConfigLoader`** — `fromYaml`: top-level keys `provider`,
   `agent_spec`, `engine_loop`, `mcp_transport`, `stop_policy`,
   `compaction`; per-field type checks with `ArgumentError` naming the key;
   unknown keys ignored. `fromEnv`: `ZFA_PROVIDER_BASE_URL`,
   `ZFA_PROVIDER_PROVIDER_KIND`, `ZFA_PROVIDER_MODEL`,
   `ZFA_PROVIDER_TIMEOUT_MS`, `ZFA_AGENT_SPEC_ID`, `ZFA_AGENT_SPEC_NAME`,
   `ZFA_AGENT_SPEC_SYSTEM_PROMPT`, `ZFA_ENGINE_LOOP_MAX_TURNS`,
   `ZFA_ENGINE_LOOP_SESSION_ID`, `ZFA_MCP_TRANSPORT_ENDPOINT`,
   `ZFA_STOP_POLICY_MAX_TURNS` — present keys populate sections; unparsable
   numeric values are `ArgumentError`s naming the variable.
5. **`SecretResolver`** — `Future<String?> fromEnv(String key)`,
   `fromFile(String path)`, `fromVault(Uri uri)`; `NullSecretResolver` stub
   returns null for all.
6. **`MissionRunner` gate** — optional `config`; at the very top of `run()`:
   issues → `StateError` whose message lists every issue; zero events, zero
   executor calls.

## Research decisions

See [research.md](./research.md): optional-sections + validate() over
required-sections; env names prefixed `ZFA_`; map-injected environment;
session-id mismatch as the incompatible rule; README example doubles as the
SC-001 test fixture source.

## Sequencing

tasks → tdd.plan → tdd.run (U1–U14, A1–A4) → tdd.verify → PR (closes #121).
