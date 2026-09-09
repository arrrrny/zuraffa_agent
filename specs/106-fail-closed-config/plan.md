# Implementation Plan: Fail-closed provider configuration (issue #117)

**Branch**: `106-fail-closed-config` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

## Summary

The provider-configuration and agent-spec services stop inventing defaults.
Constructing either without an injected configuration is a construction-time
`ArgumentError` naming the missing configuration (the issue's first remedy
option). Every vendor reference (`kilo.ai` gateway host, `tencent/hy3:free`
model id, the `'kilo'` provider id) leaves non-test code, and the fallback
chain's default ids drop the vendor id. The integration test loses its
vendor defaults — it now requires explicit environment configuration and
skips otherwise. No service interface changes; only constructor arity and
defaults.

## Technical Context

**Language/Version**: Dart 3.x (`^3.8.0`). Pure Dart, Flutter-free.

**Primary Dependencies**: none new — `package:zuraffa` (NoParams, Loggable/
FailureHandler mixins) already in use.

**Storage**: N/A.

**Testing**: `dart test` (package:test). Suite baseline at `d5dbc1f`:
1224 passed / 0 failed, analyzer clean.

**Target Platform**: Dart VM (library).

**Constraints**: constitution V (gates), X (pristine analysis); purity gate
untouched (no new dart:io); `dart analyze` stays at zero findings; the
CHANGELOG records the deliberate breaking constructor change (issue intent).

**Scale/Scope**: 3 edited lib files (constructor + defaults only), 3 edited
test files; zero new lib files; zero interface changes.

## Constitution Check

- **I. CLI-Built Only** — PASS (spec-driven pipeline; the edited providers
  are hand-curated files from spec 052, edited in place per their headers).
- **II/III. Misfire / escalate** — run under the same user-authorized
  report-and-continue protocol as spec 105; no framework defect anticipated.
- **V. Gates** — PASS (analyze/test/purity + the new vendor-strip gate).
- **VII. Purity** — PASS (no dart:io changes).
- **X. Pristine analysis** — PASS (baseline zero findings).

## Project Structure

```text
specs/106-fail-closed-config/
├── spec.md, plan.md, checklists/, research.md, tasks.md, tdd/
lib/src/data/providers/provider_config/provider_config_provider.dart  # EDIT
lib/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart  # EDIT
lib/src/data/providers/fallback_chain/fallback_chain_provider.dart    # EDIT
test/data/providers/provider_config/provider_config_provider_test.dart # EDIT
test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart # EDIT
test/integration/llm_client_proxy_test.dart                            # EDIT
```

## Components

1. **`ProviderConfigProvider`** — `required ProviderConfig config`;
   `ArgumentError` at construction when absent; `current`/`count` serve the
   injected value (`count` reports the configured models length, unchanged
   shape: still 1 for a single injected config).
2. **`YamlAgentSpecProvider`** — `required YamlAgentSpec spec`; same
   fail-closed contract; injected-spec behavior already pinned by an
   existing test (kept).
3. **`FallbackChainProvider`** — default ids become neutral client kinds
   `['anthropic', 'gemini']` (both are real in-tree client kinds); the
   vendor id is gone.
4. **Integration test** — `LLM_BASE_URL` / `LLM_MODEL` / API key become
   required; the test skips with a stated reason when any is absent.

## Research decisions

See [research.md](./research.md). Headlines: constructor-fail-closed chosen
over read-time sentinel (issue's first AC; earlier failure); fallback ids
de-vendored to real client kinds; integration test skip reason names the
three missing variables.

## Sequencing

tasks → tdd.plan → tdd.run (U1..U5, A1..A3) → tdd.verify → PR (closes #117).

## Complexity Tracking

> No constitution violations. The constructor arity change is a deliberate,
> issue-mandated breaking change, recorded in the CHANGELOG.
