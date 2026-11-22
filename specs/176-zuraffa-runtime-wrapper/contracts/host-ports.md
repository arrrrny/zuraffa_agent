# Contract: Host-injection ports

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Technology-agnostic ports the host injects (FR-006). Each port has a pure-Dart
in-memory adapter for tests and a production adapter supplied by the host.
Business logic depends on these interfaces, never on `GetIt.instance`,
a concrete WebView, an MCP socket, or a provider SDK.

Every port listed here is a **required non-nullable** field of
`AgentPortRegistry`, so host composition cannot omit one.

## AgentCredentialPort

```dart
abstract class AgentCredentialPort {
  Future<String?> resolveApiKey(String provider);   // null = not configured
  Future<void> storeApiKey(String provider, String key);
  Future<void> clearApiKey(String provider);
}
```

## AgentStoragePort

```dart
abstract class AgentStoragePort {
  Future<SessionStorage> open();                    // pi's own storage contract
  Future<void> close();
}
```

Returns pi's `SessionStorage` (`package:pi/session_storage.dart`) directly — the
wrapper defines no storage handle of its own.

## AgentEgressPort

```dart
abstract class AgentEgressPort {
  Future<AgentHttpResponse> send(AgentHttpRequest request);
}
```

`AgentHttpRequest` / `AgentHttpResponse` are this port's own value types
(declared in the port file) because pi has no HTTP seam to borrow: pi's
provider transport is pi's, and this port exists so a host can route any
wrapper-initiated traffic.

## AgentTelemetryPort

```dart
abstract class AgentTelemetryPort {
  void recordSpan(AgentSpan span);
  void recordEvent(AgentTelemetryEvent event);
  void recordError(Object error, StackTrace? trace);
}
```

## AgentArtifactPort

```dart
abstract class AgentArtifactPort {
  Future<AgentArtifactDescriptor> store(String kind, List<int> bytes);
  Future<List<int>?> resolve(String id);            // null = unknown id
}
```

`store` returns the `AgentArtifactDescriptor` entity from `data-model.md`;
`resolve` returns the bytes or null. There is no `AgentArtifactRef` type — an
unknown id is `null`, and callers that need to distinguish "missing" from
"empty" check the descriptor they already hold.

## AgentApprovalPort

```dart
abstract class AgentApprovalPort {
  Future<ApprovalDecision> request(AgentApprovalRequest request);
}
```

`ApprovalDecision` / `AgentApprovalRequest` are pi#12-adjacent; the port keeps
its own minimal shape until pi#12's durable signals land, at which point #205
bridges the two. The wrapper does not claim a durable gate (FR-010).

## AgentLifecyclePort

```dart
abstract class AgentLifecyclePort {
  Future<void> onOpening();
  Future<void> onOpened();
  Future<void> onClosing();
  Future<void> onClosed();
}
```

## Contract rule

Every port MUST have a pure-Dart in-memory adapter under `lib/src/ports/`
alongside its interface that passes the same contract suite as the production
adapter (FR-008, SC-002). The suite lives in `test/ports/` and runs against
both adapters with no branching.
