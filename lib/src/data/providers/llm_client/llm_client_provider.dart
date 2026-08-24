// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider stub for the LlmClient data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/llm_client/llm_client.dart';
import '../../../domain/services/llm_client_service.dart';

class LlmClientProvider
    with Loggable, FailureHandler
    implements LlmClientService {
  LlmClientProvider();

  @override
  Future<LlmClient> current(NoParams params) async =>
      throw UnimplementedError('Implement LlmClientProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement LlmClientProvider.count');
}
