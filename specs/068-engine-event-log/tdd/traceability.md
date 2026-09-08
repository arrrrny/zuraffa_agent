# Traceability: 068-engine-event-log

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:1836f2cd655466c2c430a30b461e93ac364a252278b3b82d67cac2353cbab612
statements: 13
automated: 13
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 37 | - **FR-001**: The system MUST satisfy this requirement: `void add(EngineEvent event)` appends one event; `void addAll(Iterable<EngineEvent> events)` appends in iteration order. Order of insertion is preserved exactly on read-back. | U1 | automated |
| FR-002 | 38 | - **FR-002**: The system MUST satisfy this requirement: `List<EngineEvent> get events` returns an **unmodifiable** copy — mutating the returned list (add/remove/clear/element assignment) throws; mutations never propagate into the log. `int get length`, `bool get isEmpty`, `bool get isNotEmpty` reflect the append count. | U2 | automated |
| FR-003 | 39 | - **FR-003**: The system MUST satisfy this requirement: `List<T> byType<T extends EngineEvent>()` returns the sub-list of events of exactly type `T`, in insertion order. `T? firstOfType<T extends EngineEvent>()` / `T? lastOfType<T extends EngineEvent>()` return the first/last such event or `null`. | U3 | automated |
| FR-004 | 40 | - **FR-004**: The system MUST satisfy this requirement: `List<EngineEvent> since(DateTime cutoff, {bool inclusive = true})` returns events with `emittedAt >= cutoff` (or `>` when `inclusive: false`), preserving order; `List<EngineEvent> before(DateTime cutoff, {bool inclusive = false})` mirrors it for `emittedAt <=`/`<` cutoff. Implementation note (design discovery during the red phase): the sealed base `EngineEvent` gains an abstract `DateTime get emittedAt;` — every subtype already carries the field, so all 9 conform without modification, and the temporal projections filter the whole union uniformly. | U4 | automated |
| FR-005 | 41 | - **FR-005**: The system MUST satisfy this requirement: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911/2 at `30b4b94` + new tests). Engine purity preserved: pure Dart, no `dart:io`, no new dependencies. | U5 | automated |
| AC-1 | 61 | 1. **Given** the feature implementation under its clean-architecture seams **When** add/addAll preserve insertion order **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A1 | automated |
| AC-2 | 63 | 2. **Given** the feature implementation under its clean-architecture seams **When** events is an unmodifiable snapshot **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A2 | automated |
| AC-3 | 65 | 3. **Given** the feature implementation under its clean-architecture seams **When** length and emptiness track appends **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A3 | automated |
| AC-4 | 67 | 4. **Given** the feature implementation under its clean-architecture seams **When** byType filters by exact type, insertion order **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A4 | automated |
| AC-5 | 69 | 5. **Given** the feature implementation under its clean-architecture seams **When** firstOfType and lastOfType **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A5 | automated |
| AC-6 | 71 | 6. **Given** the feature implementation under its clean-architecture seams **When** since filters by emission time with inclusive/exclusive boundary **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A6 | automated |
| AC-7 | 73 | 7. **Given** the feature implementation under its clean-architecture seams **When** before filters by emission time with inclusive/exclusive boundary **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A7 | automated |
| AC-8 | 75 | 8. **Given** the feature implementation under its clean-architecture seams **When** empty log behaves as empty **Then** the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | A8 | automated |

