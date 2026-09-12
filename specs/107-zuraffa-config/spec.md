**Template Version**: `zuraffa-1.0`

# Feature Specification: `ZuraffaConfig` — runtime configuration with startup validation

**Branch**: `107-zuraffa-config` (off master, post-#142) | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #121 — "Ship runtime config loader (`ZuraffaConfig`)
with startup validation". Severity: high. Related: #117 (fail-closed
providers — merged), #15/#11 (epic references).

## Summary

Every provider hand-wires its own configuration and there is no single
place a consumer can declare "this is how my engine is configured". A
misconfigured engine fails at first turn instead of at startup. This spec
ships one value object — `ZuraffaConfig` — that aggregates the six
configuration sections the engine already has (provider, agent spec, engine
loop, MCP transport, stop policy, compaction strategy), two loaders into it
(a YAML document and an environment map), a cross-cutting `validate()`
returning typed issues, a fail-fast gate in `MissionRunner.run`, and a
`SecretResolver` interface for credential sources. The config contract is
documented in the README with an example document.

Sections are optional individually; `validate()` is what decides whether a
configuration is runnable, returning typed issues — `missing` (a section
another configured section requires), `outOfRange` (a value outside its
legal bounds), `incompatible` (two configured sections that contradict each
other). `MissionRunner.run` fails before its first event when it was given a
configuration that does not validate.

**Out of scope**: hot reload, remote config fetch, wiring the loaders into
the providers from spec 106 (consumers pass `ZuraffaConfig`-produced values
to those constructors themselves), secrets *resolution* backends beyond the
stub interface, CLI flags.

## Files

- `lib/src/config/zuraffa_config.dart` — NEW: the value object (six
  nullable sections) + the sealed `ConfigIssue` family (`missing`,
  `outOfRange`, `incompatible`) + `validate()`.
- `lib/src/config/zuraffa_config_loader.dart` — NEW: `ZuraffaConfigLoader`
  with `fromYaml(String)` and `fromEnv(Map<String, String>)` (the caller
  supplies the environment map — runtime paths stay `dart:io`-free).
- `lib/src/config/secret_resolver.dart` — NEW: `SecretResolver` interface
  (`fromEnv(key)`, `fromFile(path)`, `fromVault(uri)`) + a null-returning
  stub implementation.
- `lib/src/engine/mission_runner.dart` — EDIT: optional `config` parameter;
  `run()` throws a `StateError` listing every issue before the first event
  when validation fails.
- `README.md` — EDIT: "Configuring the engine" section with the contract
  and an example document.
- `test/config/*`, `test/engine/mission_runner_config_gate_test.dart` — NEW.
- `specs/107-zuraffa-config/` — this artifact set.

## User scenarios

### US1 — One document configures the engine (P1)

As an integrator, I write one declarative configuration document, load it,
hand it to the mission runner, and every section lands where it belongs —
provider endpoint, agent spec, loop budgets, MCP transport, stop policy,
compaction — without reading source to discover the knobs.

**Acceptance**: a fully-populated document loads with every field preserved
in the typed sections; `validate()` returns no issues; the runner accepts
it.

**Acceptance Scenarios**:

1. **Given** a fully-populated configuration document, **When** it loads, **Then** every field is preserved in the typed sections, `validate()` returns no issues, and the runner accepts it.
### US2 — Environment-only configuration works (P2)

As a container operator, I configure through environment variables alone;
only the variables I set become configuration, and unknown variables are
ignored.

**Acceptance**: an environment map produces a configuration with the
corresponding sections populated; partial maps yield partial configurations;
unknown keys never become sections and never error.

**Acceptance Scenarios**:

2. **Given** an environment map (partial or full), **When** a configuration is produced from it, **Then** the corresponding sections populate, partial maps yield partial configurations, and unknown keys never become sections and never error.
### US3 — Bad configuration fails at startup, loudly and completely (P1)

As an operator, a misconfigured engine refuses to start and tells me
everything wrong at once — a missing section another section requires, a
value out of range, two sections contradicting each other — instead of
failing at first turn.

**Acceptance**: a configuration with multiple problems validates to a list
naming each problem with its section and field; the mission runner given
that configuration throws before emitting any event or calling the engine;
a valid configuration runs the mission unchanged; no configuration at all
preserves today's behavior.

**Acceptance Scenarios**:

3. **Given** a configuration with multiple problems, **When** `validate()` runs and the runner starts, **Then** the validation names each problem with its section and field, the runner throws before emitting any event or calling the engine, a valid configuration runs the mission unchanged, and no configuration preserves the pre-existing behavior.
### US4 — Credentials come from pluggable sources (P2)

As a security reviewer, credentials never live in the configuration
document; consumers implement one small interface to resolve them from
their own sources (environment, file, vault).

**Acceptance**: the resolver interface exposes the three source kinds; the
shipped stub resolves nothing (returns absence) and never throws for
absence.

**Acceptance Scenarios**:

4. **Given** the resolver interface, **When** it is inspected and exercised with absence, **Then** it exposes the three source kinds and the shipped stub resolves nothing (returns absence) and never throws.
## Edge cases

- YAML values of the wrong type for a known field are rejected with a
  diagnostic naming the field (house pattern: spec 104's loader).
- Unknown YAML top-level keys are ignored (forward compatibility — a newer
  document must not crash an older engine; spec 104 precedent).
- `maxTurns <= 0`, `timeoutMs <= 0`, and zero wall-clock timeouts are
  out-of-range issues, not exceptions.
- Two sections scoped to different session ids (engine loop vs compaction
  strategy) are an incompatible issue.
- A partial environment map produces a configuration that may not validate —
  the loader never throws for absence; validation is `validate()`'s job.

## Requirements

### Functional requirements

- **FR-001**: `ZuraffaConfig` aggregates the six sections, each
  optional, each carried verbatim; fully-populated configurations validate
  to an empty issue list.
  traces: ZuraffaConfig.fr1
- **FR-002**: the YAML loader parses a document into the typed
  sections with per-field diagnostics for wrong-typed values; unknown keys
  are ignored.
  traces: ZuraffaConfig.fr2
- **FR-003**: the environment loader maps documented variables to
  sections; absent variables leave sections absent; unknown variables are
  ignored.
  traces: ZuraffaConfig.fr3
- **FR-004**: `validate()` returns typed issues — `missing` (a
  section required by another configured section, e.g. a configured engine
  loop with no provider), `outOfRange` (non-positive budgets/limits),
  `incompatible` (sections scoped to different sessions) — each naming its
  section and field.
  traces: ZuraffaConfig.fr4
- **FR-005**: `MissionRunner.run` with a configuration that fails
  validation throws before emitting any event and before any engine
  execution; with a valid configuration it runs unchanged; without a
  configuration, behavior is unchanged.
  traces: ZuraffaConfig.fr5
- **FR-006**: the `SecretResolver` interface exposes the three source
  kinds; the shipped stub reports absence for every source without
  throwing.
  traces: ZuraffaConfig.fr6

### Key entities

- **`ZuraffaConfig`** — the aggregate; sections nullable by design.
- **`ConfigIssue`** — sealed family: missing / outOfRange / incompatible.
- **`SecretResolver`** — credential-source interface + stub.
- The six section value objects — unchanged, carried verbatim.

## Success criteria

- **SC-001** (US1 / FR-001–002): the full example document (README's)
  loads, validates clean, and every field round-trips.
- **SC-002** (US2 / FR-003): a full and a partial environment map produce
  the corresponding configurations; unknown variables ignored.
- **SC-003** (US3 / FR-004–005): a multi-problem configuration yields one
  typed issue per problem and the runner throws before its first event;
  valid/no-config runners behave exactly as before (existing mission tests
  stay green).
- **SC-004** (US4 / FR-006): the stub resolver returns absence for all
  three sources.
- **SC-005** (US1 / README): the README documents the contract with a
  runnable example document (mechanical: the section exists and its example
  parses through the loader in a test).
- **SC-006**: `dart analyze` pristine; suite green; purity gate unchanged
  (new lib files import no `dart:io`).

## Assumptions

- Sections are optional + `validate()` decides runnability (the issue's
  cross-cutting validation example — engine loop configured ⇒ provider
  required — is modeled as a `missing` issue).
- Environment variable names are prefixed `ZFA_` (documented in README);
  the map is injected so runtime purity holds and tests never touch the
  process environment.
- The loader rejects unknown *values* only where types are known; forward
  compatibility wins for unknown keys.

## Dependencies

- Builds on: master (post-#142) — the six section value objects, spec 104's
  loader diagnostics precedent, spec 106's fail-closed providers (consumers
  feed `ZuraffaConfig` sections into those constructors).
- Foundational for: #120 (per-server resilience config could extend the
  transport section later).

## Layer Contracts

**Domain**:

- `ZuraffaConfig`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`

