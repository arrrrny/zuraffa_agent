# Contract: AgentRuntimeFactory

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Opens a pi runtime from injected configuration and installs extensions. The
only place that touches pi's runtime surface; unstable pre-#12 pi details are
isolated behind the `PiRuntimeAdapter` interface in `src/pi/`.

## Signature (logical)

```dart
class AgentRuntimeFactory {
  AgentRuntimeFactory({required AgentRuntimeConfig config, required AgentPortRegistry ports});

  /// Opens the pi runtime. Fails with a typed outcome when a required port is
  /// missing or the pi durable runtime is unavailable (pre-pi#12).
  Future<AgentRuntime> open({GovernancePolicy? governance, List<AgentExtension>? extensions});
}
```

## Behavior

- Validates `config` (`modelProvider`/`modelId` non-empty; tool names known).
- Validates `ports` (all seven ports non-null) — else
  `AgentConfigurationOutcome.missingPort(name)`.
- Calls `PiRuntimeAdapter.open(...)` to build the pi `Agent`/`Conversation`.
  Before pi#12 lands, durable features return a typed
  "pi durable runtime unavailable" outcome; the factory still opens a
  non-durable conversation.
- Installs `governance` as pi `beforeTool`/`afterTool` hooks and any
  `extensions` into pi's registry via `PiExtensionBootstrap`.

## Failure modes

- `missingPort(name)` — a required port was not injected.
- `durableUnavailable()` — pi#12 surface requested before it exists.
- `invalidConfig(reason)` — config failed validation.

No failure reads `GetIt.instance` (FR-006).