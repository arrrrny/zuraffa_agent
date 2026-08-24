// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// McpTransport sealed (in-proc/SSE/stdio) value object - spec-exact from epic #1 §R3 (issue #4).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// McpTransport sealed (in-proc/SSE/stdio) value object.
///
/// Sealed transport — in-proc (same-isolate), SSE+Bearer (reconnect, auth callback), stdio (subprocess pipe). One client interface, three transports (epic #3 §R3.3, issue #4 US3).
class McpTransport {
  final String id;
  final String transportType;
  final String endpoint;
  final bool authRequired;

  const McpTransport({
    required this.id,
    required this.transportType,
    required this.endpoint,
    required this.authRequired,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpTransport &&
          runtimeType == other.runtimeType && id == other.id && transportType == other.transportType && endpoint == other.endpoint && authRequired == other.authRequired);

  @override
  int get hashCode => Object.hash(id, transportType, endpoint, authRequired);

  @override
  String toString() =>
      'McpTransport(id: $id, transportType: $transportType, endpoint: $endpoint)';
}
