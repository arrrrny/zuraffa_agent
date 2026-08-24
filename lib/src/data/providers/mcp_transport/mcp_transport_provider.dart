// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider stub for the McpTransport data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/mcp_transport/mcp_transport.dart';
import '../../../domain/services/mcp_transport_service.dart';

class McpTransportProvider
    with Loggable, FailureHandler
    implements McpTransportService {
  McpTransportProvider();

  @override
  Future<McpTransport> current(NoParams params) async =>
      throw UnimplementedError('Implement McpTransportProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement McpTransportProvider.count');
}
