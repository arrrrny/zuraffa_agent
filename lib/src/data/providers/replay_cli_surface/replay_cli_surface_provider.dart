// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the ReplayCliSurface data layer. Returns the active
// replay CLI surface snapshot (declarative replay invocation) as a
// constructed default (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/replay_cli_surface/replay_cli_surface.dart';
import '../../../domain/services/replay_cli_surface_service.dart';

class ReplayCliSurfaceProvider
    with Loggable, FailureHandler
    implements ReplayCliSurfaceService {
  final ReplayCliSurface _active;

  ReplayCliSurfaceProvider([ReplayCliSurface? active])
      : _active = active ??
            const ReplayCliSurface(
              id: 'default',
              missionId: 'mission-0',
              graderMatrixId: 'grader-0',
              verbosity: 'normal',
            );

  @override
  Future<ReplayCliSurface> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
