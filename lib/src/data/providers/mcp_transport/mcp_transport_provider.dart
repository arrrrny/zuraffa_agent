// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider for the McpTransport data layer. Returns the active
// transport descriptor (in-proc/SSE/stdio). Replaces the previous
// UnimplementedError stub (spec 031).
//
// NOTE: McpTransport normally needs network I/O, but for this
// production-readiness pass it is implemented with in-memory/constructed
// state. Real transport I/O is a later phase.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/mcp_transport/mcp_transport.dart';
import '../../../domain/services/mcp_transport_service.dart';

class McpTransportProvider
    with Loggable, FailureHandler
    implements McpTransportService {
  final McpTransport _active;

  McpTransportProvider([McpTransport? active])
      : _active = active ??
            const McpTransport(
              id: 'inproc',
              transportType: 'in-proc',
              endpoint: 'in-process',
              authRequired: false,
            );

  @override
  Future<McpTransport> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
