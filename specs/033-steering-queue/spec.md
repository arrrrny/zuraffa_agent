# Feature Specification: SteeringQueue + SteeringMessage (R1 engine core)

**Branch**: `033-steering-queue` | **Date**: 2026-08-24

## Summary
Hand-curated `SteeringQueue` + `SteeringMessage` value objects — spec-exact from epic #1 §R1.3 (issue #2 body: "Steering & follow-up queues (pi-mono pattern): mid-mission user input injected between turns without losing state"). The repo already ships the `SteeringInjected` lifecycle event (`lib/src/engine/events/steering_injected.dart`); this PR adds the **queue** that holds the pending messages between turns — the data structure the engine drains when it pops the next steering input.

This advances epic issue #2 (R1 — engine core). The streaming events (R1.5) and stop conditions (R1.4) already landed; this fills the R1.3 gap — the queue + message data model the loop consults between turns.

## Files
- `lib/src/domain/entities/steering_message/steering_message.dart` — `SteeringMessage` value object (id + content + injectedAt; value-based equality).
- `lib/src/domain/entities/steering_queue/steering_queue.dart` — `SteeringQueue` value object (id + pending (List<SteeringMessage>) + processedCount + lastInjectedAt; value-based equality; `isEmpty` / `pendingCount` / `head` getters).
- `lib/src/domain/services/steering_queue_service.dart` — abstract `SteeringQueueService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/steering_queue/steering_queue_provider.dart` — concrete `SteeringQueueProvider` stub (UnimplementedError bodies).
- `test/data/providers/steering_queue/steering_queue_provider_test.dart` — 9 regression tests (6 entity + 3 clean-arch).
- `specs/033-steering-queue/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 9 new tests pass

## Advances #2 (R1 — engine core)
