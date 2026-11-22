# Contract: Host-injection ports

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Technology-agnostic ports the host injects (FR-006). Each port has a pure-Dart
in-memory adapter for tests and a production adapter supplied by the host.
Business logic depends on these interfaces, never on `GetIt.instance`,
a concrete WebView, an MCP socket, or a provider SDK.

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
  Future<AgentStorageHandle> open();                 // pi Storage adapter factory
  Future<void> close();
}
```

## AgentEgressPort

```dart
abstract class AgentEgressPort {
  Future<AgentHttpResponse> send(AgentHttpRequest request); // injectable HTTP
}
```

## AgentTelemetryPort

```dart
abstract class AgentTelemetryPort {
  void recordSpan(AgentSpan span);                   // pi telemetry contract bridge
  void recordEvent(AgentTelemetryEvent event);
  void recordError(Object error, StackTrace? trace);
}
```

## AgentArtifactPort

```dart
abstract class AgentArtifactPort {
  Future<AgentArtifactDescriptor> store(String kind, List<int> bytes);
  Future<AgentArtifactRef?> resolve(String id);
}
```

## AgentApprovalPort

```dart
abstract class AgentApprovalPort {
  Future<ApprovalDecision> request(AgentApprovalRequest request);
}
```

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

Every port MUST have a pure-Dart in-memory adapter under
`lib/src/data/permission/` (or `lib/src/data/ports/`) that passes the same
contract suite as the production adapter (FR-008, SC-002). The suite lives in
`test/ports/` and runs against both adapters with no branching.