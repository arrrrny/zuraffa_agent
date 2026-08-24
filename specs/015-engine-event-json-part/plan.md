# Implementation Plan: EngineEvent json_serializable part directive
**Branch**: `015-engine-event-json-part` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Add `part 'engine_event.g.dart';` directive + minimal placeholder part file. The hand-curated library has no `@Zorphy` annotations on the subtypes yet, so the .g.dart file is intentionally empty (just the `part of` directive + a comment) until json_serializable is wired through.

## Phase 1 — Design

### engine_event.dart update
Append `part 'engine_event.g.dart';` after the existing 9 subtype `part` directives.

### engine_event.g.dart (new file)
```dart
// GENERATED — placeholder for json_serializable output.
// See issue arrrrny/zuraffa_agent#15.
//
// The hand-curated EngineEvent subtypes (turn_started, turn_completed, etc.)
// do not yet carry @Zorphy annotations, so json_serializable emits no code
// here. When @Zorphy is added to the subtypes (or when zfa ships a sealed-
// class-aware generator), build_runner will write the _$XFromJson/_$XToJson
// helpers into this file and the `part 'engine_event.g.dart';` directive
// already in engine_event.dart will pick them up.
part of 'engine_event.dart';
```

## Phase 2 — Tasks
See `tasks.md`.
