// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (UI/tree+json payloads).
//
// Concrete provider stub for the UiTreePayload data layer. Mirrors the
// ToolResultProvider pattern from PR #49, the AgentSessionProvider from
// PR #50, the AgentToolProvider from PR #52, the CircuitBreakerProvider
// from PR #53, the SubAgentSpecProvider from PR #54, and the
// PassAtKProvider from PR #55: bodies throw UnimplementedError so the
// file is analyzable without forcing real I/O. Parameterless methods
// (current, count) declare NoParams params so the @override clause
// matches the UiTreePayloadService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/ui_tree_payload/ui_tree_payload.dart';
import '../../../domain/services/ui_tree_payload_service.dart';

class UiTreePayloadProvider
    with Loggable, FailureHandler
    implements UiTreePayloadService {
  UiTreePayloadProvider();

  @override
  Future<UiTreePayload> current(NoParams params) async =>
      throw UnimplementedError('Implement UiTreePayloadProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement UiTreePayloadProvider.count');
}
