# Test List: 111-grader-diversity

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | Composed multi-grader acceptance: a registry holding one grader of each family resolves all four by id and evaluates them against a shared mission-output fixture, returning one verdict per binding with the expected pass/fail per family (`test/eval/graders/graders_test.dart`). | SC-005 | PENDING |
| A2 | Repo gates: `dart analyze` zero; `dart test` green; purity gate unchanged. | SC-006 | PENDING |

## Inner loop: unit behaviors

### Component: `lib/src/eval/graders/` (deterministic graders)

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | ExactMatchGrader: passes on equality (trim honored), fails otherwise, reason carries expected + actual. | FR-002 | PENDING |
| U2 | RegexGrader: passes when the pattern matches, fails naming the pattern in the reason. | FR-003 | PENDING |

### Component: `lib/src/eval/graders/json_path_grader.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U3 | Resolves `$.a.b[0].c`-style paths against a JSON payload and passes on value equality. | FR-004 | PENDING |
| U4 | Missing path, mismatched value, and malformed JSON each FAIL with a reason naming the path / the problem — never throw. | FR-004 | PENDING |

### Component: `lib/src/eval/graders/llm_judge_grader.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U5 | A `PASS`-prefixed judge response with a reason yields a passing verdict carrying that reason; the judge message contains the judge prompt and the output. | FR-005 | PENDING |
| U6 | A `FAIL`-prefixed response yields a failing verdict with its reason. | FR-005 | PENDING |
| U7 | An unparsable response yields a failing verdict whose reason quotes the raw response. | FR-005 | PENDING |

### Component: `lib/src/eval/graders/grader_registry.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U8 | Register + resolve by id; an unknown id fails with a typed error naming it. | FR-006 | PENDING |
| U9 | Evaluate-in-bulk returns one verdict per binding id. | FR-006 | PENDING |

## Out of scope (do not add tests)

- Golden-mission corpus; CI eval gating; UI schema/snapshot graders.

## Verification commands

```bash
dart test test/eval/graders/
dart test
dart analyze
```
