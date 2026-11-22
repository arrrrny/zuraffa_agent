# Contract: Governance hooks

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

**Scope note**: governance **policy** is issue #205. This contract describes
the seam this feature owns — the point at which a capability extension's hook
bodies reach pi — and the pi surfaces that seam feeds. It does not specify
allowlists, risk tiers, or redaction rules; #205 does, as one
`ZuraffaExtension`.

## What pi actually provides

pi's only configuration seam is `AgentOptions` (`pi_agent/lib/src/agent.dart`).
The relevant fields, verified on `arrrrny/pi` `master`:

```dart
final Future<List<Map<String, dynamic>>> Function(List<AgentMessage>)? convertToLlm;
final Future<List<AgentMessage>> Function(List<AgentMessage>, {bool Function()? isAborted})? transformContext;
final Future<BeforeToolCallResult?> Function(BeforeToolCallContext, {bool Function()? isAborted})? beforeToolCall;
final Future<AfterToolCallResult?> Function(AfterToolCallContext, {bool Function()? isAborted})? afterToolCall;
```

There is **no** provider-request hook. `grep` for `onProviderRequest`,
`ProviderRequestHook`, and `beforeProvider` over `pi_agent/lib` returns zero
matches, so a contract that promised one would be describing a pi that does
not exist.

## The seam this feature owns

```dart
class ZuraffaExtension {
  final String id;
  final BeforeToolCallHookCallback? beforeToolCall;
  final AfterToolCallHookCallback? afterToolCall;
  final TransformContextCallback? transformContext;
  final ConvertToLlmCallback? convertToLlm;
}
```

`ExtensionBootstrap` composes the installed extensions into one
`AgentExtensionHooks` value, which `PiRuntimeAdapter.open` passes to
`AgentOptions`. Composition rules:

1. Every hook field is optional; an extension supplies only what it needs.
2. With no extension installed, the bootstrap yields all-null hooks and the
   runtime behaves exactly as pi does. The wrapper contributes no hook and no
   policy of its own (FR-009, SC-005).
3. With more than one extension, hooks compose in installation order. A hook
   that returns a non-null result short-circuits the chain for that hook (this
   is pi's own contract: a non-null `BeforeToolCallResult` replaces the tool
   call).

## What #205 installs through it

Recorded here only so the seam's shape is justified — never implemented here:

- **Argument guards, allowlists, risk tiers, approvals** → `beforeToolCall`
  (denial happens before execution).
- **Tool-result minimization, artifact references, tool-result redaction** →
  `afterToolCall` (it sees tool results).
- **PII scrubbing of anything else the model would receive** →
  `transformContext`. This is load-bearing: `afterToolCall` only ever sees
  **tool results**, so content the model itself generated, or content already
  sitting in the transcript from a previous turn, never passes through it.
  `transformContext` is the last thing to touch `List<AgentMessage>` before
  the provider call, which is where "the model never receives the unredacted
  content" can actually be enforced.
- **Fail-closed** differs per seam because the return types differ:
  `beforeToolCall`/`afterToolCall` return a result object, so a broken
  extension can return a rejection; `transformContext` returns a message list,
  so its only fail-closed move is to throw (or emit a redaction-error
  placeholder message) and let the runtime's error boundary surface it. #205
  states which it chooses; the seam's job is not to hide the difference.

## Audit

Audit/metrics observation of commits, task phases, submissions, tool calls and
provider events is #205's extension too, bridged to `AgentTelemetryPort`. The
wrapper itself records nothing.
