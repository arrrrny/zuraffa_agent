// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the HealthSnapshot data layer. Returns the active
// chain-state snapshot (per-provider open/closed/half-open state) as a
// constructed default (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/health_snapshot/health_snapshot.dart';
import '../../../domain/services/health_snapshot_service.dart';

class HealthSnapshotProvider
    with Loggable, FailureHandler
    implements HealthSnapshotService {
  final HealthSnapshot _active;

  HealthSnapshotProvider([HealthSnapshot? active])
      : _active = active ??
            const HealthSnapshot(
              id: 'default',
              chainId: 'chain-0',
              capturedAt: 0,
              healthyProviders: 1,
              trippedProviders: 0,
            );

  @override
  Future<HealthSnapshot> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
