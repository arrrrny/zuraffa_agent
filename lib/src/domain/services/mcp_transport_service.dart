// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Service interface for the McpTransport value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/mcp_transport/mcp_transport.dart';

/// Service surface for the McpTransport value object.
abstract class McpTransportService with Loggable, FailureHandler {
  /// Returns the current McpTransport snapshot for the active mission.
  Future<McpTransport> current(NoParams params);

  /// Returns the count of McpTransport records for the active mission.
  Future<int> count(NoParams params);
}
