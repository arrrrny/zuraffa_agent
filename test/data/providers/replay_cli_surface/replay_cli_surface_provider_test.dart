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

    test('ReplayCliSurfaceProvider.current throws UnimplementedError on NoParams', () {
      final provider = ReplayCliSurfaceProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ReplayCliSurfaceProvider.count throws UnimplementedError on NoParams', () {
      final provider = ReplayCliSurfaceProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
