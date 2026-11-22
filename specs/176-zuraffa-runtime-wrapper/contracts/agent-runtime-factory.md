# Contract: AgentRuntimeFactory

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Opens a pi runtime from injected configuration and installs extensions. The
facade is thin by contract: it validates what composition can leave wrong,
constructs through `PiRuntimeAdapter`, and returns pi's objects.

## Signature (logical)

```dart
class AgentRuntimeFactory {
  AgentRuntimeFactory({
    required AgentRuntimeConfig config,
    required AgentPortRegistry ports,
  });

  /// Opens the pi runtime and returns pi's own Conversation.
  /// Live only once `/pi#12` has landed (FR-010).
  Future<Conversation> open({List<ZuraffaExtension> extensions = const []});
}
```

## Behavior

- Validates `config`: `modelProvider` and `modelId` are non-empty. It does NOT
  validate tool names against a "known" set — pi owns the tool registry and
  this package has no tool catalog to check against (data-model.md,
  `AgentRuntimeConfig`).
- Does NOT validate `ports` at runtime. `AgentPortRegistry` declares all seven
  ports as required non-nullable constructor arguments, so a missing port is a
  compile error at the composition root. There is no `missingPort` outcome to
  produce and none is advertised.
- Composes `extensions` into `AgentExtensionHooks` via `ExtensionBootstrap`,
  then calls `PiRuntimeAdapter.open(config, ports, hooks)`.
- Returns pi's `Conversation` unchanged. No wrapper result type wraps it, and
  no wrapper-authored outcome is returned in its place.

## Extension composition

- Zero extensions → all-null hooks → the runtime behaves exactly as pi does
  (FR-009, SC-005).
- One or more extensions → non-null hooks composed in installation order; a
  non-null `BeforeToolCallResult` short-circuits, which is pi's own semantics.

## Failure modes

- **Compile error** — a required port was omitted (the whole class of
  "missing port" failures).
- **pi error surfaced as-is** — an invalid model, provider failure, or
  construction failure throws or returns what pi throws or returns. The
  wrapper does not translate pi failures into a parallel error taxonomy.
- No failure path reads `GetIt.instance` (FR-006).

## Before pi#12

`open` does not exist as a functioning path: implementation starts after
`arrrrny/pi#12` lands, because the durable surface and its types are what the
facade returns. There is no non-durable fallback mode and no
`durableUnavailable()` outcome (FR-010; operator blocking review item 2).
