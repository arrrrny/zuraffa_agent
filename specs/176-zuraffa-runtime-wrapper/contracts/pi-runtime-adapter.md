# Contract: Pi runtime adapter (construction boundary)

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

The only file that **constructs** pi's runtime. It builds the pi `Agent` /
`Conversation` from the wrapper's config, ports, and composed extension hooks,
and it absorbs construction/lifecycle drift in pi's API (FR-005). A pi
signature change touches this adapter, not every host.

It is **not** a type boundary: the package declares `pi` directly and its
public API returns and re-exports pi's own types. Nothing here aliases a pi
type into a wrapper-owned one.

## Public pi contracts consumed

From `package:pi/pi.dart` (verified against `arrrrny/pi` `master`,
`pi_agent/lib/src/harness.dart`):

- `Agent` / `Conversation` (`Conversation.create` / `resume` / `prompt` /
  `fork` / `compact`, `Stream<AgentEvent> get events`) — agent runtime and
  transcript.
- `AgentEvent` stream (start/end/turn/message/tool-execution events).
- `SessionStorage` — transcript persistence seam.
- `AgentTool`, `BeforeToolCallHook`, `AfterToolCallHook` — tools + hooks.
- `AgentOptions.transformContext` / `AgentOptions.convertToLlm` — the two
  message/context seams pi actually exposes.
- `Model` / `Usage` / `AgentMessage` family — provider/model types.
- `CompactionSettings` / `CompactionResult` — pi-owned compaction.

There is no extension registry and no provider-request hook in the Dart port.
This contract names neither, and the wrapper invents neither.

## pi#12 surface — not yet available

Submissions, request-ID deduplication, durable inboxes, watches, tasks, the
durable scheduler, checkpoints, replay policy, signals, memoized values,
parked tools, nested calls, approval gates, foreground/background subagents,
durable compaction, provider session identity, telemetry, usage accounting.

This contract declares **no** stand-in for any of them. When pi#12 lands, the
facade returns those pi types directly, and the adapter implements its methods
to return them — at that point, not before (FR-003, FR-010).

## Interface (logical)

```dart
abstract class PiRuntimeAdapter {
  /// Builds and opens pi's runtime. The hooks come from the extension seam.
  Future<Conversation> open(
    AgentRuntimeConfig config,
    AgentPortRegistry ports,
    AgentExtensionHooks hooks,
  );
}
```

- `open` returns pi's `Conversation`. Submission/watch/task/outcome methods
  are added when pi#12 provides their types — they are absent, not stubbed,
  before then.
- `AgentExtensionHooks` is the bootstrap's output (`beforeToolCall`,
  `afterToolCall`, `transformContext`, `convertToLlm`), each nullable, each
  handed straight to `AgentOptions`. The adapter composes; it does not decide.

## Rule

Only this file constructs pi's runtime. Pi **type** references and re-exports
elsewhere are expected and allowed (the facade's return types are pi's), and
any file that names a pi type declares the `pi` dependency itself rather than
leaning on transitive visibility (FR-005, architecture plan §4).
