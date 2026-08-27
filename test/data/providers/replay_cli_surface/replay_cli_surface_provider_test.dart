// HAND-CURATED regression tests for the ReplayCliSurface value object +
// ReplayCliSurfaceProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/replay_cli_surface/replay_cli_surface.dart';
import 'package:zuraffa_agent/src/domain/services/replay_cli_surface_service.dart';
import 'package:zuraffa_agent/src/data/providers/replay_cli_surface/replay_cli_surface_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - ReplayCliSurface value equality', () {
    test('ReplayCliSurface equality is value-based across all fields', () {
      final a = ReplayCliSurface(id: 'id-a', missionId: 'ref-1', graderMatrixId: 'ref-1', verbosity: 'info');
      final b = ReplayCliSurface(id: 'id-a', missionId: 'ref-1', graderMatrixId: 'ref-1', verbosity: 'info');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ReplayCliSurface inequality differs when a field changes', () {
      final a = ReplayCliSurface(id: 'id-a', missionId: 'ref-1', graderMatrixId: 'ref-1', verbosity: 'info');
      final b = ReplayCliSurface(id: 'id-b', missionId: 'ref-2', graderMatrixId: 'ref-2', verbosity: 'info');
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - ReplayCliSurface clean-arch layers', () {
    test('ReplayCliSurfaceProvider is a ReplayCliSurfaceService', () {
      final provider = ReplayCliSurfaceProvider();
      expect(provider, isA<ReplayCliSurfaceService>());
    });

    test('ReplayCliSurfaceProvider.current returns the active replay CLI surface', () async {
      final provider = ReplayCliSurfaceProvider();
      final surface = await provider.current(NoParams());
      expect(surface, isA<ReplayCliSurface>());
      expect(surface.id, 'default');
      expect(surface.missionId, 'mission-0');
      expect(surface.graderMatrixId, 'grader-0');
      expect(surface.verbosity, 'normal');
    });

    test('ReplayCliSurfaceProvider.count returns 1', () async {
      final provider = ReplayCliSurfaceProvider();
      expect(await provider.count(NoParams()), 1);
    });

    test('ReplayCliSurfaceProvider honours an injected value object', () async {
      final custom = ReplayCliSurface(
        id: 'custom',
        missionId: 'mission-x',
        graderMatrixId: 'grader-x',
        verbosity: 'verbose',
      );
      final provider = ReplayCliSurfaceProvider(custom);
      final surface = await provider.current(NoParams());
      expect(surface.id, 'custom');
      expect(surface.verbosity, 'verbose');
    });
  });
}
