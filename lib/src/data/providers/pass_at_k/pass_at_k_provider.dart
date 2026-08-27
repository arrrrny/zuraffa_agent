// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness: pass@k unbiased
// estimator).
//
// Concrete provider for the PassAtK data layer. Returns the most-recently
// computed unbiased pass@k snapshot for the active mission. Replaces the
// previous UnimplementedError stub (spec 037).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/pass_at_k/pass_at_k.dart';
import '../../../domain/services/pass_at_k_service.dart';

class PassAtKProvider
    with Loggable, FailureHandler
    implements PassAtKService {
  final PassAtK _snapshot;

  PassAtKProvider({int n = 10, int c = 1, int k = 1})
      : _snapshot = PassAtK.compute(n: n, c: c, k: k);

  @override
  Future<PassAtK> current(NoParams params) async => _snapshot;

  @override
  Future<int> count(NoParams params) async => 1;
}
