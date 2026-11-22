# Contract: Pi runtime adapter (isolation boundary)

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

The only file that touches pi's runtime surface. It converts the wrapper's
logical model into pi's public contracts and keeps unstable pre-#12 details
behind this interface (FR-005). A pi signature change touches this adapter,
not every host.

## Public pi contracts consumed (available today)

From `package:pi/pi.dart` (verified against the local pi checkout):

- `Agent` / `Conversation` (`Conversation.create` / `resume` / `prompt` /
  `fork` / `compact` / `events` / `close`) — agent runtime and transcript.
- `AgentEvent` stream (start/end/turn/message/tool-execution events).
- `SessionStorage` — transcript persistence seam.
- `AgentTool` / `BeforeToolCallHook` / `AfterToolCallHook` — tool + governance.
- `Model` / `Usage` / `AgentMessage` family — provider/model types.
- `CompactionSettings` / `CompactionResult` — pi-owned compaction.

## Not-yet-available (pi#12) — isolated behind this interface

- Submissions, request-ID deduplication, durable inboxes.
- Watches, tasks, durable scheduler, checkpoints, replay policy.
- Signals, memoized values, parked tools, nested calls.
- Approval gates, foreground/background subagents, durable compaction.
- Provider session identity, telemetry, usage accounting.

## Interface (logical)

```dart
abstract class PiRuntimeAdapter {
  Future<Conversation> open(AgentRuntimeConfig config, AgentPortRegistry ports);
  Future<PiSubmissionOutcome> submit(Conversation c, String prompt);
  Future<PiWatch> watch(Conversation c);
  Future<PiTask> task(Conversation c, PiTaskSpec spec);
  Future<PiOutcome> outcome(PiSubmissionOutcome o);
}
```

- `PiSubmissionOutcome` / `PiWatch` / `PiTask` / `PiOutcome` are wrapper-owned
  interfaces that map to pi#12 types when they land; before pi#12 they map to
  the pi `AgentEvent` stream + `Conversation` results and never claim durable
  behavior.
- Any call whose durable feature is unavailable returns a typed
  `durableUnavailable()` outcome (SC-001 edge case).

## Rule

No other file imports `package:pi/*` directly except through this adapter
(Five: keep unstable details behind interfaces). The wrapper's public facade
returns pi types (Conversation, outcomes) — not parallel result models
(FR-003).