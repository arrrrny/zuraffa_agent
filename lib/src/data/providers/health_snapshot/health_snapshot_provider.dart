// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider stub for the HealthSnapshot data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/health_snapshot/health_snapshot.dart';
import '../../../domain/services/health_snapshot_service.dart';

class HealthSnapshotProvider
    with Loggable, FailureHandler
    implements HealthSnapshotService {
  HealthSnapshotProvider();

  @override
  Future<HealthSnapshot> current(NoParams params) async =>
      throw UnimplementedError('Implement HealthSnapshotProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement HealthSnapshotProvider.count');
}
