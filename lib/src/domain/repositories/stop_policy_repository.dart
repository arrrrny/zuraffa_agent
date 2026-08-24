// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#14.
//
// zfa v6.0.0's `zfa make <Entity> repository usecase di mock provider service
// datasource` crashes for every entity with an unhandled type cast
// (`type 'bool' is not a subtype of type 'String?'`). The clean-architecture
// layers never emit. This file is the canonical hand-curated repository
// interface for the StopPolicy value object that ships in the consuming repo
// until zfa ships the matching fix.
//
// StopPolicy is a value object (single instance per logical id), so the
// repository surface is much simpler than a CRUD aggregate: read current +
// update + reset.

import 'package:zuraffa/zuraffa.dart';

import '../entities/stop_policy/stop_policy.dart';

abstract class StopPolicyRepository with Loggable, FailureHandler {
  /// Returns the current [StopPolicy] for the given [id].
  Future<StopPolicy> getCurrent(String id);

  /// Persists the [policy] (full replace; value objects are immutable).
  Future<StopPolicy> update(StopPolicy policy);

  /// Resets the [id]'s policy to its default state.
  Future<void> reset(String id);
}
