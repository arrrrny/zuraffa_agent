# Test List: 106-fail-closed-config

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | Both config services compose the fail-closed contract end to end: constructing without a configuration throws naming the missing configuration, and constructing with one serves the injected values verbatim through the existing service interface (`test/data/providers/provider_config/provider_config_provider_test.dart` + `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | SC-001, SC-003 | PENDING |
| A2 | Vendor-strip gates: a case-insensitive search for the gateway host and model id returns zero hits outside `specs/`; the `'kilo'` provider id is absent from library defaults; the integration test file carries no vendor default and requires its environment variables (mechanical checks, commands in the verification commands block). | SC-002, SC-004 | PENDING |
| A3 | Repo gates: `dart analyze` zero findings; `dart test` green (baseline 1224 ± test delta); purity gate unchanged. | SC-005 | PENDING |

## Inner loop: unit behaviors

### Component: `lib/src/data/providers/provider_config/provider_config_provider.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | Constructing without a configuration throws `ArgumentError` at construction, naming the missing configuration. | FR-001 | PENDING |
| U2 | A configured provider serves the injected configuration verbatim through `current()` and reports count 1 — explicitly-configured consumers are unaffected. | FR-003 | PENDING |

### Component: `lib/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U3 | Constructing without a spec throws `ArgumentError` at construction, naming the missing spec. | FR-002 | PENDING |
| U4 | A configured spec provider serves the injected spec verbatim (existing injected-value pin retained and still green). | FR-003 | PENDING |

### Component: `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U5 | The default fallback chain's provider ids contain no vendor id — neutral client kinds only. | FR-004 | PENDING |

## Invariants and edge cases

- An explicitly-provided configuration never trips the fail-closed path
  (pinned by U2/U4's verbatim assertions).
- The integration test's skip is a stated-reason skip, not a silent default
  (covered by A2's mechanical check of the file).

## Out of scope (do not add tests)

- Runtime config loading (`ZuraffaConfig`, issue #121 — next spec).
- Value-object field validation; service interface shapes; fallback-chain
  runtime behavior (specs 008/053).

## Verification commands (from .specify/memory/tdd-profile.md)

```bash
dart test
dart analyze
rg -i "kilo\.ai|hy3" --glob '!specs/**' .    # A2 gate (expect: no matches)
rg "'kilo'" lib/                              # A2 gate (expect: no matches)
```
