# Test List: 004-providers-and-fallback

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | events, tool-call buffering, and usage fields parse identically across providers. | AC-1 | PENDING |
| A2 | dart_agent_core is absent; vendored files carry attribution. | AC-2 | PENDING |
| A3 | its ledger entry exists with provider + model + token counts. | AC-3 | PENDING |
| A4 | B serves it; the mission observes only latency. | AC-4 | PENDING |
| A5 | a half-open probe routes real traffic back on success. | AC-5 | PENDING |
| A6 | the policy restarts on the next provider (or surfaces, per config) — never silently truncates. | AC-6 | PENDING |
| A7 | it matches the internal breaker states. | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The engine MUST provide OpenAI-compatible, Anthropic, and Gemini clients behind one `LlmClient` interface on engine primitives. | FR-001 | PENDING |
| U2 | Provider code MUST be vendored from dart_agent_core with attribution; dart_agent_core MUST NOT appear in the dependency graph. | FR-002 | PENDING |
| U3 | Every call MUST account usage into the UsageLedger. | FR-003 | PENDING |
| U4 | A fallback chain MUST advance on connection/timeout/5xx/context-overflow/repeated-429 with per-provider circuit breaker (open/half-open/closed) and explicit mid-stream policy. | FR-004 | PENDING |
| U5 | A health snapshot API MUST expose chain state. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 41]
route: A4 -> acceptance lane [declared: type marker, spec line 54]
route: A5 -> acceptance lane [declared: type marker, spec line 56]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: A7 -> acceptance lane [declared: type marker, spec line 71]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

