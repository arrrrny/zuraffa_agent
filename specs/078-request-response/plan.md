# Implementation Plan: Request/response pattern (spec 078)

## Approach

Additive edit to `AgentController` (three members + doc refresh), a new
test file that drives both the new controller surface and pins the bus's
request/response semantics. The bus implementation itself is NOT changed
— its current behavior is correct; it was unguarded. Pins are proven by
deliberate mutants (013's own A2 cycle-log precedent).

## Components

### 1. `AgentController` additions (`lib/src/events/event_bus.dart`)

```dart
EventBus get bus => _bus;                       // FR-003
void on<T>(void Function(T) listener) =>
    _bus.on<T>(listener);                       // FR-002 alias
Future<R> request<R>(Object event) =>
    _bus.request<R>(event);                     // FR-001 parity
```

The stale `// Stub: no delivery until implemented.` comment (left from
A4's cycle) is replaced with real docs. No change to `EventBus` internals.

### 2. Tests (`test/events/request_response_test.dart`)

New-surface tests (RED via missing members, compile failure):

- T1: controller.request returns the handler's typed response (US1).
- T2: controller.on subscribes exactly like listen (FR-002).
- T3: controller/bus parity — same bus, same handler, request through
  both surfaces returns the identical response (FR-001 / SC-003).

Pinned-semantics tests (pass immediately against current behavior —
guarded by mutants M3–M6):

- T4: multiple handlers → last-registered responds (FR-004).
- T5: handler throws → error propagates to the requester (FR-005).
- T6: no handler → StateError naming the type (FR-006).
- T7: wrong R → TypeError surfaces, never a silent value (FR-007).
- T8: late registration serves later requests; distinct types dispatch
  independently (FR-008).

### 3. Mutations (M1–M6, one at a time, cp-restored)

- M1: `controller.request` throws UnimplementedError instead of
  delegating (guards T1/T3).
- M2: `controller.on` is a no-op (guards T2).
- M3: bus dispatches to FIRST-registered handler instead of last
  (guards T4/T8).
- M4: bus swallows handler exceptions (guards T5).
- M5: bus drops the no-handler StateError (guards T6).
- M6: bus erases the `as R` response cast (guards T7).

## Sequencing

1. RED — test file vs missing `AgentController.request` / `on` / `bus`
   (compile errors: undefined members).
2. GREEN — the three members land; target file 8/8.
3. Mutations M1–M6.
4. Gates + verification.md + commit + PR (base master).

## Risks / decisions

- **Additive-only edit on a file with direct-to-master history**
  (A1–A4): no rewrites, no reformatting of existing code; the diff must
  read as three additions.
- **Pins are not RED**: T4–T8 pass against existing behavior by design.
  The cycle-log/verification states this explicitly and each pin is
  justified by its killer mutant — an unguarded pin would be theater.
- **`bus` getter is a spec'd extension** (FR-003): 013's prose lists
  four controller methods but leaves handler registration reachable only
  via constructor injection; the wrap must be transparent to be usable.
