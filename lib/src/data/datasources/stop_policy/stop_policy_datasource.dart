// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#27 (uri_does_not_exist) and
// arrrrny/zuraffa_agent#28 (implements_non_class).
//
// Root cause: `zfa make <Entity> ... datasource` in value-object mode emits
// the mock datasource (`stop_policy_mock_datasource.dart`) that imports this file
// and `implements StopPolicyDatasource`, but value-object mode SKIPS emitting
// the datasource file itself — the mock references a file zfa itself decided
// not to emit. The fix surface: ship a hand-curated datasource interface so
// the mock_datasource's import + implements clause resolve.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/stop_policy/stop_policy.dart';

/// Data-source interface for the StopPolicy value object.
///
/// Policy surface for the engine loop's stop conditions: max turns, wall-clock timeout, token budget, repetition threshold. Producers produce typed StopOutcome outcomes.
abstract class StopPolicyDatasource with Loggable, FailureHandler {
  /// Returns the current state of the StopPolicy (single instance — value object).
  Future<StopPolicy> current();

  /// Resets the StopPolicy state to its initial value.
  Future<void> reset();
}
