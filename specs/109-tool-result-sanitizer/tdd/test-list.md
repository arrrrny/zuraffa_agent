# Test List: 109-tool-result-sanitizer

## Outer loop: acceptance behaviors

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | A mission whose tool returns secret-bearing content produces a transcript with markers and zero original secret substrings when the sanitizer is injected; verbatim without it (`test/engine/mission_runner_sanitizer_test.dart`). | SC-004 | DONE |
| A2 | Repo gates: `dart analyze` zero findings; `dart test` green; purity gate unchanged. | SC-005 | DONE |

## Inner loop: unit behaviors

### Component: `lib/src/security/tool_result_sanitizer.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | AWS access key id → `[REDACTED:aws-access-key-id]`; surrounding text intact. | FR-002 | DONE |
| U2 | GitHub PAT → `[REDACTED:github-pat]`. | FR-002 | DONE |
| U3 | JWT → `[REDACTED:jwt]`. | FR-002 | DONE |
| U4 | Private-key block header → `[REDACTED:private-key-header]`. | FR-002 | DONE |
| U5 | Slack token → `[REDACTED:slack-token]`. | FR-002 | DONE |
| U6 | Stripe live key → `[REDACTED:stripe-live-key]`. | FR-002 | DONE |
| U7 | Benign corpus (incl. pattern lookalikes) round-trips unchanged, zero matched rules. | FR-003 | DONE |
| U8 | Config: disabled rule leaves its secret intact; custom pattern fires under its own name; custom marker template honored. | FR-004 | DONE |

### Component: `lib/src/engine/mission_runner.dart` (wiring)

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U9 | With a sanitizer, a tool result containing a secret joins the transcript redacted (marker present, original absent). | FR-005 | DONE |
| U10 | Without a sanitizer the transcript is byte-identical to today's behavior. | FR-005 | DONE |

## Out of scope (do not add tests)

- Audit-log emission (no audit log exists; hook = matchedRules).
- Prompt/input sanitization; binary content.

## Verification commands

```bash
dart test test/security/ test/engine/mission_runner_sanitizer_test.dart
dart test
dart analyze
```
