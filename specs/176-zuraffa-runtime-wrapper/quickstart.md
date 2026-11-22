# Quickstart: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Validation guide proving the wrapper works end-to-end. Run from the package
root after implementation — that is, after `arrrrny/pi#12` lands, since no
scenario below can run against a pi without the durable surface (FR-010).
Prerequisites: the repo's Dart SDK constraint (`^3.8.0`) and a `pi` dependency
that carries pi#12.

## Setup

```sh
# from repo root (package is the repo itself)
dart pub get
dart analyze            # constitution X: 0 errors, 0 warnings
dart test -j 2          # fleet guard: overrides dart_test.yaml's concurrency 4
```

## Scenario 1 — Open a runtime and run a scripted conversation (SC-001)

1. Build the runtime config with in-memory host adapters. Every port is
   required, so this literal must supply all seven or it does not compile:

```dart
final config = AgentRuntimeConfig(
  modelProvider: 'scripted',
  modelId: 'scripted-model',
  systemPrompt: 'You are a helpful assistant.',
);

final ports = AgentPortRegistry(
  credentials: InMemoryAgentCredentialPort(),
  storage: InMemoryAgentStoragePort(),
  egress: InMemoryAgentEgressPort(),
  telemetry: InMemoryAgentTelemetryPort(),
  artifacts: InMemoryAgentArtifactPort(),
  approvals: InMemoryAgentApprovalPort(),
  lifecycle: InMemoryAgentLifecyclePort(),
);

final factory = AgentRuntimeFactory(config: config, ports: ports);
final conversation = await factory.open();   // pi Conversation
```

2. Submit a prompt and read the pi objects back:

```dart
await conversation.prompt('hi');
final events = conversation.events;            // pi Stream<AgentEvent>
```

**Expected**: `conversation` is pi's `Conversation`; the submission/outcome
objects read off it are pi types; no wrapper result model appears in any
signature.

## Scenario 2 — A missing port does not compile (FR-006)

The guarantee is compile-time, so the "test" is a negative compile:

```dart
// This MUST NOT compile — `credentials` is a required named argument.
final ports = AgentPortRegistry(
  storage: InMemoryAgentStoragePort(),
  egress: InMemoryAgentEgressPort(),
  telemetry: InMemoryAgentTelemetryPort(),
  artifacts: InMemoryAgentArtifactPort(),
  approvals: InMemoryAgentApprovalPort(),
  lifecycle: InMemoryAgentLifecyclePort(),
);
```

**Expected**: `error: The named parameter 'credentials' is required but
wasn't provided.` There is no runtime `missingPort` outcome to assert and no
`GetIt.instance` fallback to escape through.

## Scenario 3 — Extension seam (SC-005)

1. Install a test extension and confirm its hooks reach the runtime:

```dart
final extension = ZuraffaExtension(
  id: 'test-extension',
  beforeToolCall: (ctx, {isAborted}) async {
    return BeforeToolCallResult.reject('denied by test extension');
  },
);

final conversation = await factory.open(extensions: [extension]);
```

2. Open with no extension and confirm the wrapper contributed nothing:

```dart
final bare = await factory.open();
```

**Expected**: with the extension installed, the runtime's `AgentOptions`
carries the extension's `beforeToolCall` and a denied tool is rejected before
execution; with none installed, every hook in the opened options is null.

> Governance policy (allowlists, risk tiers, PII scrubbing, audit) is issue
> #205 and ships as its own `ZuraffaExtension`. It is not asserted here.

## Scenario 4 — No forbidden imports (SC-003 / SC-004)

```sh
# these must produce no matches
grep -rn "package:zuraffa_browser" lib/ || echo "OK: no browser import"
grep -rn "LlmToolLoop\|MissionRunner" lib/ || echo "OK: no parallel runtime"
dart analyze
```

**Expected**: no browser imports, no `LlmToolLoop`/`MissionRunner` in the new
runtime, analyzer pristine.

## Scenario 5 — Contract suite parity (SC-002)

```sh
dart test -j 2 test/ports/          # same suite runs against in-memory adapters
```

**Expected**: identical pass set for in-memory and production adapters; no
per-adapter branching in the suite.
