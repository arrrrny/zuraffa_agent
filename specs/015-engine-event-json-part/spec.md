# Feature Specification: EngineEvent json_serializable part directive

**Branch**: `015-engine-event-json-part` | **Date**: 2026-08-24

## Summary
Add the `part 'engine_event.g.dart';` directive to `lib/src/engine/events/engine_event.dart` and ship a minimal placeholder `engine_event.g.dart` part file with the matching `part of` directive. Issue #15 surfaces the zfa-template bug where `zfa entity create --sealed` writes only `part 'engine_event.zorphy.dart';` and omits the json_serializable part directive, so the generated `_$XFromJson`/`_$XToJson` helpers are unreachable and every consumer that switches over `EngineEvent` fails to compile.

The hand-curated `engine_event.dart` library shipped by PRs #33–#42 currently has no `@Zorphy` annotations on its subtypes, so json_serializable emits no code for them. This PR still adds the part directive + an explicitly-empty placeholder part file so that:
1. The structure matches the zfa generator's intended output.
2. When `@Zorphy` annotations are added later (or when zfa ships a consistent generator), `build_runner` produces the matching `engine_event.g.dart` and the part directive is already in place — no template patch required.

## Files
- `lib/src/engine/events/engine_event.dart` — add `part 'engine_event.g.dart';` directive after the 9 subtype parts.
- `lib/src/engine/events/engine_event.g.dart` — new placeholder file: `part of 'engine_event.dart';` + a comment block explaining the reservation.
- `specs/015-engine-event-json-part/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All 156 tests still pass

## Closes #15
