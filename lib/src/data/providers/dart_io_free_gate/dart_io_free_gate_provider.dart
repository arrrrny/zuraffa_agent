// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the DartIoFreeGate data layer. Returns the active
// static gate snapshot (fails the build if the eval runtime imports the
// platform IO module) as a constructed default (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/dart_io_free_gate/dart_io_free_gate.dart';
import '../../../domain/services/dart_io_free_gate_service.dart';

class DartIoFreeGateProvider
    with Loggable, FailureHandler
    implements DartIoFreeGateService {
  final DartIoFreeGate _active;

  DartIoFreeGateProvider([DartIoFreeGate? active])
      : _active = active ??
            const DartIoFreeGate(
              id: 'default',
              gateName: 'dart-io-free',
              enforcedPaths: ['lib/src'],
              violationCount: 0,
            );

  @override
  Future<DartIoFreeGate> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
