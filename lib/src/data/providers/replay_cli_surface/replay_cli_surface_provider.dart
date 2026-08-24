// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the ReplayCliSurface data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/replay_cli_surface/replay_cli_surface.dart';
import '../../../domain/services/replay_cli_surface_service.dart';

class ReplayCliSurfaceProvider
    with Loggable, FailureHandler
    implements ReplayCliSurfaceService {
  ReplayCliSurfaceProvider();

  @override
  Future<ReplayCliSurface> current(NoParams params) async =>
      throw UnimplementedError('Implement ReplayCliSurfaceProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ReplayCliSurfaceProvider.count');
}
