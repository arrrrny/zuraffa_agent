# Test List: 107-zuraffa-config

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | The README's example document loads through the YAML loader, validates to an empty issue list with every field round-tripped, and a mission runner holding it runs a scripted mission to completion (`test/config/zuraffa_config_loader_test.dart` + `test/engine/mission_runner_config_gate_test.dart`). | SC-001 | PENDING |
| A2 | A configuration with multiple problems (missing provider + non-positive maxTurns) yields one typed issue per problem and the runner throws before emitting any event or calling the executor (`test/engine/mission_runner_config_gate_test.dart`). | SC-003 | PENDING |
| A3 | The README's "Configuring the engine" section exists and its example document is the exact fixture A1 parses (mechanical check in `test/config/zuraffa_config_loader_test.dart`). | SC-005 | PENDING |
| A4 | Repo gates: `dart analyze` zero findings; `dart test` green; purity gate unchanged (no dart:io in new lib files). | SC-006 | PENDING |

## Inner loop: unit behaviors

### Component: `lib/src/config/zuraffa_config.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The aggregate carries all six sections verbatim (identity/equality), each independently nullable. | FR-001 | PENDING |
| U2 | `validate()` on a fully-populated configuration returns an empty list. | FR-001, FR-004 | PENDING |
| U3 | `validate()`: a configured engine loop with no provider section yields a `missing` issue naming both sections (the issue's example). | FR-004 | PENDING |
| U4 | `validate()`: `engineLoop.maxTurns <= 0`, `providerConfig.timeoutMs <= 0`, and a negative stop-policy wall-clock timeout each yield an `outOfRange` issue naming section + field. | FR-004 | PENDING |
| U5 | `validate()`: engine loop and compaction strategy scoped to different session ids yield an `incompatible` issue naming both. | FR-004 | PENDING |

### Component: `lib/src/config/zuraffa_config_loader.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U6 | `fromYaml` full document → every section populated with the documented fields. | FR-002 | PENDING |
| U7 | `fromYaml` partial document → only present sections; unknown top-level keys ignored. | FR-002 | PENDING |
| U8 | `fromYaml` wrong-typed known field → `ArgumentError` naming the field. | FR-002 | PENDING |
| U9 | `fromEnv` full map → corresponding sections populated (numeric variables parsed). | FR-003 | PENDING |
| U10 | `fromEnv` partial map → only present variables; unknown variables ignored; unparsable numeric value → `ArgumentError` naming the variable. | FR-003 | PENDING |

### Component: `lib/src/config/secret_resolver.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U11 | The stub resolver returns absence for all three sources without throwing. | FR-006 | PENDING |

### Component: `lib/src/engine/mission_runner.dart` (gate)

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U12 | Runner with an invalid configuration: `run()` throws `StateError` listing every issue; zero events emitted; executor never called. | FR-005 | PENDING |
| U13 | Runner with a valid configuration runs the mission unchanged (events flow, result returned). | FR-005 | PENDING |
| U14 | Runner without a configuration behaves exactly as before (existing mission tests remain the pin; new test asserts a no-config run is unaffected). | FR-005 | PENDING |

## Out of scope (do not add tests)

- Hot reload, remote config fetch, provider-constructor wiring, secrets
  resolution backends, CLI flags (spec out-of-scope list).

## Verification commands

```bash
dart test test/config/
dart test test/engine/mission_runner_config_gate_test.dart
dart test
dart analyze
rg -n "dart:io" lib/src/config/   # expect: no matches (purity)
```
