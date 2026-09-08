# Test List: 084-llm-retry-backoff

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/llm/retry_084_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/llm/retry_test.dart`). | AC-14 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U6 | The system MUST satisfy this requirement: ) already retry 429/5xx with capped exponential backoff behind an | FR-006 | PENDING |
| U1 | The system MUST satisfy this requirement: The retryable set is exactly: HTTP 429, HTTP 5xx, and | FR-001 | PENDING |
| U2 | The system MUST satisfy this requirement: Backoff for computed delays is exponential | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: A `Retry-After` header in seconds form is honored UNCLAMPED: | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: Network errors (`LlmNetworkException`) are retried under the | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: On exhaustion the final error is typed and | FR-005 | PENDING |
| U6 | The system MUST satisfy this requirement: Timing is deterministic under the injected clock: the same | FR-006 | PENDING |
| U7 | The system MUST satisfy this requirement: `openStreamWithRetry` follows the identical policy on the | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | FR-008 | PENDING |
| U3 | The system MUST satisfy this requirement: /FR-005. | FR-003 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 190]
route: A2 -> acceptance lane [declared: type marker, spec line 192]
route: A3 -> acceptance lane [declared: type marker, spec line 194]
route: A4 -> acceptance lane [declared: type marker, spec line 196]
route: A5 -> acceptance lane [declared: type marker, spec line 198]
route: A6 -> acceptance lane [declared: type marker, spec line 200]
route: A7 -> acceptance lane [declared: type marker, spec line 202]
route: A8 -> acceptance lane [declared: type marker, spec line 204]
route: A9 -> acceptance lane [declared: type marker, spec line 206]
route: A10 -> acceptance lane [declared: type marker, spec line 208]
route: A11 -> acceptance lane [declared: type marker, spec line 210]
route: A12 -> acceptance lane [declared: type marker, spec line 212]
route: A13 -> acceptance lane [declared: type marker, spec line 214]
route: A14 -> acceptance lane [declared: type marker, spec line 216]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

