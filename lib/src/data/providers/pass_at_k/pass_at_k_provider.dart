// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 — eval harness: pass@k unbiased
// estimator).
//
// Concrete provider stub for the PassAtK data layer. Mirrors the
// ToolResultProvider pattern from PR #49, the AgentSessionProvider from
// PR #50, the AgentToolProvider from PR #52, the CircuitBreakerProvider
// from PR #53, and the SubAgentSpecProvider from PR #54: bodies throw
// UnimplementedError so the file is analyzable without forcing real I/O.
// Parameterless methods (current, count) declare NoParams params so the
// @override clause matches the PassAtKService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/pass_at_k/pass_at_k.dart';
import '../../../domain/services/pass_at_k_service.dart';

class PassAtKProvider
    with Loggable, FailureHandler
    implements PassAtKService {
  PassAtKProvider();

  @override
  Future<PassAtK> current(NoParams params) async =>
      throw UnimplementedError('Implement PassAtKProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement PassAtKProvider.count');
}
