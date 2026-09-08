# Traceability: 25-repetition_tracker-datasource-pair

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:9e1f11d00dc628b1a6ede82b439f52e28c1a032bd8b1563e5a3d59bb00a99322
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a tracker configured `maxCalls=3, window=60s`, **When** the same signature is recorded 2 times, **Then** `isLooping` is false and `count` returns 2. | A1 | automated |
| AC-2 | 27 | 2. **Given** the same tracker, **When** the same signature is recorded a 3rd time, **Then** `isLooping` is true (threshold met — "more than N times in the last M seconds" is inclusive of the Nth hit). | A2 | automated |
| AC-3 | 29 | 3. **Given** two different signatures recorded 3 times each with `maxCalls=3`, **Then** both loop independently — counts are keyed per signature, never shared. | A3 | automated |
| AC-4 | 44 | 4. **Given** `window=60s` and 3 records at `T0`, **When** `count`/`isLooping` are evaluated at `T0+61s`, **Then** count is 0 and no loop is signalled. | A4 | automated |
| AC-5 | 46 | 5. **Given** records at `T0` and `T0+50s` with `window=60s`, **When** evaluated at `T0+61s`, **Then** only the second record counts (boundary: exactly `window` old is expired; strictly inside is alive). | A5 | automated |
| AC-6 | 61 | 6. **Given** a mock with 3 recorded signatures, **When** `reset()` is called, **Then** all counts drop to 0, no signature loops, and `current()` still returns the same configuration. | A6 | automated |
| AC-7 | 63 | 7. **Given** any conforming implementation, **When** `record` returns, **Then** it returns the post-record in-window count for that signature (single round-trip read-after-write). | A7 | automated |
| FR-001 | 77 | - **FR-001**: The `RepetitionTracker` value object MUST expose the loop-detection configuration — `id`, `maxCalls` (N), `window` (M) — with value equality across all fields. | U1 | automated |
| FR-002 | 78 | - **FR-002**: `RepetitionTracker` MUST expose a pure predicate `isRepetition(observedCalls)` that returns true iff `observedCalls >= maxCalls`, so threshold logic is testable without a datasource. | U2 | automated |
| FR-003 | 79 | - **FR-003**: The datasource interface MUST define the persistence contract: `current()`, `reset()`, `record(signature)`, `count(signature)`, `isLooping(signature)` — all asynchronous. | U3 | automated |
| FR-004 | 80 | - **FR-004**: `record` MUST accept an optional injectable timestamp; `count`/`isLooping` MUST accept an optional injectable evaluation time, so window behavior is deterministically testable. | U4 | automated |
| FR-005 | 81 | - **FR-005**: The mock datasource MUST implement in-memory sliding-window tracking: per-signature timestamp lists, pruned to the window at write and read time. | U5 | automated |
| FR-006 | 82 | - **FR-006**: `isLooping(signature)` MUST equal `current().isRepetition(count(signature))` — the signal is always derived from the live window count and the configured threshold. | U6 | automated |
| FR-007 | 83 | - **FR-007**: `reset()` MUST clear every recorded signature history while preserving the tracker configuration returned by `current()`. | U7 | automated |
| FR-008 | 84 | - **FR-008**: The entity, interface, and mock MUST keep constructor backward compatibility: `RepetitionTracker({required id})` and `RepetitionTrackerMockDatasource()` must keep compiling with sensible defaults (`maxCalls=5`, `window=60s`). | U8 | automated |

