/// Host-injection port for telemetry / failure reporting (FR-006).
///
/// The wrapper records nothing of its own (governance/audit is #205); this
/// port is the seam a host's telemetry backend plugs into. Tests use
/// [InMemoryAgentTelemetryPort].
library;

/// A telemetry span the host records.
class AgentSpan {
  final String name;
  final Map<String, dynamic> attributes;

  const AgentSpan(this.name, {this.attributes = const {}});
}

/// A telemetry event the host records.
class AgentTelemetryEvent {
  final String name;
  final Map<String, dynamic> attributes;

  const AgentTelemetryEvent(this.name, {this.attributes = const {}});
}

/// Records spans, events, and errors on behalf of the host.
abstract class AgentTelemetryPort {
  void recordSpan(AgentSpan span);
  void recordEvent(AgentTelemetryEvent event);
  void recordError(Object error, StackTrace? trace);
}

/// Pure-Dart in-memory [AgentTelemetryPort] that collects everything recorded.
class InMemoryAgentTelemetryPort implements AgentTelemetryPort {
  final List<AgentSpan> spans = [];
  final List<AgentTelemetryEvent> events = [];
  final List<Object> errors = [];

  @override
  void recordSpan(AgentSpan span) => spans.add(span);

  @override
  void recordEvent(AgentTelemetryEvent event) => events.add(event);

  @override
  void recordError(Object error, StackTrace? trace) => errors.add(error);
}
