# Quickstart: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Validation guide proving the wrapper works end-to-end. Run from the package
root after implementation. Prerequisites: Dart ^3.11 SDK; `pi` dependency
resolvable (gated on `arrrrny/pi#12` for durable behavior).

## Setup

```sh
# from repo root (package is the repo itself)
dart pub get
dart analyze            # constitution X: 0 errors, 0 warnings
dart test -j 2
```

## Scenario 1 — Open a runtime and run a scripted conversation (SC-001)

1. Build the runtime config with in-memory host adapters:

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
final runtime = await factory.open();
```

2. Submit a prompt and read the pi objects back:

```dart
final conversation = runtime.conversation;      // pi Conversation
final submission = await runtime.submit('hi');   // pi submission/outcome
final outcome = submission.outcome;              // pi outcome — not a wrapper model
```

**Expected**: `conversation` is a pi `Conversation`; `outcome` is a pi
outcome type; no wrapper result model appears in the signatures.

## Scenario 2 — Missing port fails closed (SC-001)

```dart
final ports = AgentPortRegistry(/* all but credentials */);
final factory = AgentRuntimeFactory(config: config, ports: ports);
await expectLater(factory.open(), emitsAgentConfigurationError(
  named: 'credentials',
));
```

**Expected**: a typed `AgentConfigurationOutcome` naming `credentials`; no
`GetIt.instance` fallback.

## Scenario 3 — Governance deny + redaction (SC-005)

1. Register a deny-list policy and a scrubbing policy:

```dart
final policy = GovernancePolicy(
  toolDenyList: ['dangerous_tool'],
  redactionRules: [RedactionRule.email()],
  requireApprovalForTiers: [RiskTier.high],
);
final runtime = await factory.open(governance: policy);
```

2. Attempt a denied tool and return PII:

```dart
final denied = await runtime.submit('call dangerous_tool');
expect(denied.outcome.phase, AgentPhase.toolDenied);      // denied before execution

final scrubbed = await runtime.submit('return my email a@b.com');
expect(scrubbed.outcome.exposedContent.contains('a@b.com'), isFalse); // redacted
```

3. Force a sanitizer failure:

```dart
final failed = await runtime.submit('trigger sanitizer error');
expect(failed.outcome.kind, AgentOutcomeKind.failure);     // fail closed
```

**Expected**: denial before execution; redaction before the model sees
content; a failed sanitizer yields a typed failure with no unredacted content.

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