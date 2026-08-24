// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider stub for the ToolRegistry data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/tool_registry/tool_registry.dart';
import '../../../domain/services/tool_registry_service.dart';

class ToolRegistryProvider
    with Loggable, FailureHandler
    implements ToolRegistryService {
  ToolRegistryProvider();

  @override
  Future<ToolRegistry> current(NoParams params) async =>
      throw UnimplementedError('Implement ToolRegistryProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ToolRegistryProvider.count');
}
