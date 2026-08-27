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
//
// Refined under specs/27-stop_policy-datasource-pair: the interface now
// carries the full persistence contract for the single-instance value
// object — read (current), full-replace write (update), restore-default
// (reset) — so a Hive- or remote-backed implementation can replace the
// mock without touching the repository/provider/engine above it.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/stop_policy/stop_policy.dart';

/// Data-source interface for the StopPolicy value object.
///
/// Policy surface for the engine loop's stop conditions: max turns,
/// wall-clock timeout, repetition threshold, enabled. Producers produce
/// typed StopOutcome outcomes when conditions are met (enforcement lives in
/// the engine loop, spec 002 — this contract only persists and serves the
/// policy).
abstract class StopPolicyDatasource with Loggable, FailureHandler {
  /// Returns the live policy (single instance — value object).
  Future<StopPolicy> current();

  /// Fully replaces the stored policy with [policy] (value objects are
  /// immutable — update is a whole-value replace) and returns what was
  /// stored.
  Future<StopPolicy> update(StopPolicy policy);

  /// Restores the stored policy to [StopPolicy.defaultPolicy].
  Future<void> reset();
}
