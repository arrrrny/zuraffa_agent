# Feature Specification: EngineEvent.ProviderError

**Branch**: `18-engine-event-provider-error` | **Date**: 2026-08-24

## Summary
Add `ProviderError` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted when a provider call fails terminally (auth, rate-limit, network). Pairs with the fallback chain (spec-004).

## Files
- `lib/src/engine/events/provider_error.dart` — `final class ProviderError extends EngineEvent` with `emittedAt: DateTime` + providerName: String, error: String.
- `lib/src/engine/events/engine_event.dart` — add `part 'provider_error.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `ProviderError` case; add is-A + payload tests.
- `specs/18-engine-event-provider-error/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 150 tests pass

## Closes #18
