// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the DartIoFreeGate data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/dart_io_free_gate/dart_io_free_gate.dart';
import '../../../domain/services/dart_io_free_gate_service.dart';

class DartIoFreeGateProvider
    with Loggable, FailureHandler
    implements DartIoFreeGateService {
  DartIoFreeGateProvider();

  @override
  Future<DartIoFreeGate> current(NoParams params) async =>
      throw UnimplementedError('Implement DartIoFreeGateProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement DartIoFreeGateProvider.count');
}
