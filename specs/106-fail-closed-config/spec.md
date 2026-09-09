**Template Version**: `zuraffa-1.0`

# Feature Specification: Fail-closed provider configuration — strip the hardcoded vendor default

**Branch**: `106-fail-closed-config` (off master `d5dbc1f`) | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #117 — "Strip hardcoded `kilo.ai` default
`ProviderConfig` — fail closed on missing config". Severity: high
(security/configuration). Epic: R4 — providers & fallback (issue #5).

## Summary

A consumer who constructs the provider-configuration service with no
arguments silently targets a third-party SaaS gateway
(`https://api.kilo.ai/api/gateway`, model `tencent/hy3:free`). The same
vendor reference is baked into the integration test's defaults and a
hardcoded default agent spec (id `default`, allowlist `read_file`/`list_dir`)
is served by the spec provider. Production agents must never silently route
conversations to a vendor the consumer did not choose: **missing
configuration must fail loudly at construction, not silently at first turn**.

This spec:

1. **Makes both config providers fail closed** — constructing the provider
   configuration service or the agent-spec service without an injected
   configuration is a construction-time error; the service never invents a
   default.
2. **Strips every vendor reference from non-test code** — the gateway URL,
   the model id, and the `'kilo'` provider id disappear from the library
   (including the fallback-chain default ids).
3. **Makes the integration test honest** — instead of defaulting to the
   vendor when environment variables are absent, it skips with a clear
   message unless the operator explicitly configures an endpoint.

Scope is deliberately a removal + contract tightening: no new surfaces, no
loader (the runtime config loader is issue #121, the next spec).

**Out of scope**: the runtime config loader (`ZuraffaConfig.fromYaml` /
`fromEnv` — issue #121); secrets resolution; any change to the value
objects' own field validation; changing any provider's public service
interface (only the constructors' arity and the defaults change).

## Files

- `lib/src/data/providers/provider_config/provider_config_provider.dart` —
  EDIT: the optional positional config becomes required; constructing
  without one throws immediately.
- `lib/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart` —
  EDIT: same treatment; the hardcoded `id: 'default'` spec is removed.
- `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart` —
  EDIT: the default chain's provider ids drop the vendor id (neutral ids
  only).
- `test/integration/llm_client_proxy_test.dart` — EDIT: requires explicit
  endpoint/model/token environment configuration; skips otherwise (no
  vendor default).
- `test/data/providers/provider_config/provider_config_provider_test.dart`,
  `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart` —
  EDIT: inject explicit configurations; assert the fail-closed contract.
- `specs/106-fail-closed-config/` — this artifact set.

## User scenarios

### US1 — No configuration means no service (P1)

As an integrator, if I forget to configure a provider, I find out the
moment I construct the engine — with an error naming the missing
configuration — never as a silent request to a third-party gateway at first
turn.

**Acceptance**: constructing the provider-configuration service without an
injected configuration throws immediately with an error naming the missing
configuration; the same holds for the agent-spec service; a configured
service returns exactly the configuration that was injected.

### US2 — No vendor references ship in the library (P2 — the issue's hygiene acceptance)

As a security reviewer, I can grep the shipped library and find zero
third-party gateway or model references, so no code path can silently
default to a vendor.

**Acceptance**: a case-insensitive search for the gateway host and the model
id over the library returns zero hits; the fallback chain's default ids
contain no vendor-specific id; the integration test's vendor defaults are
gone (env-required instead).

### US3 — Existing consumers keep working when explicit (P1)

As an existing consumer who already injects an explicit configuration,
nothing changes: my configuration is served verbatim, and the service
interface is unchanged.

**Acceptance**: an explicitly configured provider returns the injected
configuration through the same interface; the count surface reports the
configured set without invention.

## Edge cases

- Constructing with an explicitly-provided configuration must never throw
  (only the missing-configuration path fails).
- The integration test's skip must not count as a vendor default: no URL
  string may remain anywhere under `test/` either (the AC extends the strip
  to the test file that carried it).
- Injected empty/null-like configurations are the value objects' own
  validation concern (unchanged); this spec only governs presence of a
  configuration at construction.

## Requirements

### Functional requirements

- **FR-001** (US1): constructing the provider-configuration service without
  an injected configuration fails at construction with a typed error naming
  the missing configuration.
- **FR-002** (US1): constructing the agent-spec service without an injected
  configuration fails at construction the same way.
- **FR-003** (US3): a configured service returns the injected configuration
  verbatim through its existing interface; behavior is otherwise unchanged.
- **FR-004** (US2): after this spec, a case-insensitive search for the
  gateway host and model id returns zero hits in **non-test code** (the
  issue's own scope: `lib/` and tooling) and in the integration test that
  carried the vendor default; the fallback chain's default ids contain no
  vendor id. Inert fixture model strings inside engine unit tests are
  explicitly out of scope — they are literal test data, never routed.
- **FR-005** (US2): the integration test requires explicit environment
  configuration for endpoint/model/token and skips (with a stated reason)
  when they are absent — it never falls back to a default vendor.

### Key entities

- **ProviderConfig / YamlAgentSpec / FallbackChain** (existing value
  objects) — unchanged; only who supplies them changes.
- **The two config providers + the fallback provider** (existing services)
  — constructor contracts tightened from "optional with invented default" to
  "required".

## Success criteria

- **SC-001** (US1 / FR-001–002): constructing either service without a
  configuration throws at construction, naming the missing configuration;
  constructing with one never throws on that path.
- **SC-002** (US2 / FR-004): the vendor-host and model-id search returns
  zero hits in non-test code and the integration test; the `'kilo'`
  provider id is gone from library defaults.
- **SC-003** (US3 / FR-003): explicitly configured services behave exactly
  as before — same interface, same returned values.
- **SC-004** (FR-005): the integration test skips with a stated reason when
  environment configuration is absent, and carries no vendor default.
- **SC-005**: `dart analyze` pristine; full suite green; purity gate
  unchanged.

## Assumptions

- The issue offers two remedies (constructor-fails-closed vs sentinel
  throwing at read time); the constructor-fails-closed remedy is chosen
  (first acceptance criterion) — earlier failure, smaller blast radius.
- The integration test remains env-gated (existing tier), only losing its
  vendor defaults.
- Breaking-change note: constructing these providers without arguments was
  possible before and is an error now — this is the issue's explicit intent,
  recorded in the CHANGELOG entry.

## Dependencies

- Builds on: master `d5dbc1f` — value objects (spec 052 corpus) and the
  provider services are stable.
- Pairs with: issue #121 (runtime config loader — next spec), which gives
  consumers a structured way to produce the now-required configurations.
- Related but out of scope: fallback-chain runtime behavior (spec 008/053),
  value-object validation, secrets resolution (part of #121).
