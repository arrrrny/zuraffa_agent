# Implementation Plan: EngineEvent sealed library + TurnStarted

**Branch**: `024-engine-event-turn-started` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary

Establish `lib/src/engine/events/engine_event.dart` as a sealed-class library with one `final class TurnStarted extends EngineEvent` part, plus the future `engine_event.g.dart` part directive reserved for json_serializable output. Add the library to the public package export. Tests assert the `is`-relationship and that a `switch` over `EngineEvent` is exhaustive when only `TurnStarted` is handled with a `default` arm.

## Technical Context

**Language/Version**: Dart 3.13.1, sealed classes available since Dart 3.0. ✓

**Primary Dependencies**: `package:zuraffa/zuraffa.dart` (for `Loggable` etc., if needed by the engine); not strictly required for the sealed class declaration itself.

**Storage**: None — events are runtime-emitted, not persisted.

**Testing**: `dart test` (package:test).

**Constraints**: MUST NOT import `dart:io`. MUST NOT regress 134 pre-existing tests.

## Constitution Check

Spec-003 (tools-and-mcp) and spec-002 (engine-core-loop) define the event surface this library implements. The hand-curated file does not violate either spec; it surfaces the data type ahead of the upstream zfa fix.

Runtime purity: no `dart:io` import. ✓

## Project Structure

```text
lib/src/engine/events/
├── engine_event.dart        # sealed class EngineEvent — library entry
├── turn_started.dart        # final class TurnStarted extends EngineEvent — part
└── (future) engine_event.g.dart  # reserved for json_serializable

test/engine/events/
└── engine_event_test.dart   # is-A + switch exhaustiveness tests

lib/zuraffa_agent.dart        # export added
```

## Phase 0 — Research (summarized)

**Q1: Are sealed classes available in this Dart SDK?**
Yes — Dart 3.13.1; sealed classes landed in Dart 3.0.

**Q2: How does `invalid_use_of_type_outside_library` trigger?**
When a sealed class is declared in library A and a class in library B `extends`/`implements`/`with` it. The fix is to declare the subtypes as `part of` library A.

**Q3: Why does the zfa generator emit broken subtypes?**
The `--generate-subs` flag emits each subtype as its own entity library (under `lib/src/domain/entities/<name>/`), so each subtype is in a different library from the sealed `EngineEvent`. This is a zfa codegen defect; the consuming repo hand-curates the correct library structure ahead of the upstream fix.

## Phase 1 — Design

### Library layout

```dart
// lib/src/engine/events/engine_event.dart
library engine_event;

part 'turn_started.dart';
part 'engine_event.g.dart'; // reserved for json_serializable (issue #15)

sealed class EngineEvent {
  const EngineEvent();
}
```

```dart
// lib/src/engine/events/turn_started.dart
part of 'engine_event.dart';

final class TurnStarted extends EngineEvent {
  final DateTime emittedAt;
  final String? turnId;
  const TurnStarted({required this.emittedAt, this.turnId});
}
```

### Public export

Add to `lib/zuraffa_agent.dart`:
```dart
export 'src/engine/events/engine_event.dart';
```

### Test

```dart
test('TurnStarted is an EngineEvent', () {
  expect(const TurnStarted(emittedAt: ...), isA<EngineEvent>());
  expect(const TurnStarted(emittedAt: ...), isA<TurnStarted>());
});

test('switch over EngineEvent is exhaustive with default', () {
  String describe(EngineEvent e) => switch (e) {
    TurnStarted(:final turnId) => 'turn_started($turnId)',
    _ => 'unknown',
  };
  expect(describe(const TurnStarted(emittedAt: ..., turnId: 't1')), 'turn_started(t1)');
});
```

### Quickstart

```bash
cd /workspace/zuraffa_agent/.worktrees/024-engine-event-turn-started
dart pub get
dart analyze --fatal-infos
dart test
```

## Phase 2 — Tasks

See `tasks.md`.
