// HAND-CURATED regression tests for the HealthSnapshot value object +
// HealthSnapshotProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/health_snapshot/health_snapshot.dart';
import 'package:zuraffa_agent/src/domain/services/health_snapshot_service.dart';
import 'package:zuraffa_agent/src/data/providers/health_snapshot/health_snapshot_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#5 - HealthSnapshot value equality', () {
    test('HealthSnapshot equality is value-based across all fields', () {
      final a = HealthSnapshot(id: 'id-a', chainId: 'ref-1', capturedAt: 10, healthyProviders: 10, trippedProviders: 10);
      final b = HealthSnapshot(id: 'id-a', chainId: 'ref-1', capturedAt: 10, healthyProviders: 10, trippedProviders: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('HealthSnapshot inequality differs when a field changes', () {
      final a = HealthSnapshot(id: 'id-a', chainId: 'ref-1', capturedAt: 10, healthyProviders: 10, trippedProviders: 10);
      final b = HealthSnapshot(id: 'id-b', chainId: 'ref-2', capturedAt: 20, healthyProviders: 20, trippedProviders: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#5 - HealthSnapshot clean-arch layers', () {
    test('HealthSnapshotProvider is a HealthSnapshotService', () {
      final provider = HealthSnapshotProvider();
      expect(provider, isA<HealthSnapshotService>());
    });

    test('HealthSnapshotProvider.current throws UnimplementedError on NoParams', () {
      final provider = HealthSnapshotProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('HealthSnapshotProvider.count throws UnimplementedError on NoParams', () {
      final provider = HealthSnapshotProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
