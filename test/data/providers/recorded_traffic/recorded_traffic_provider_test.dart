// HAND-CURATED regression tests for the RecordedTraffic value object +
// RecordedTrafficProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/recorded_traffic/recorded_traffic.dart';
import 'package:zuraffa_agent/src/domain/services/recorded_traffic_service.dart';
import 'package:zuraffa_agent/src/data/providers/recorded_traffic/recorded_traffic_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - RecordedTraffic value equality', () {
    test('RecordedTraffic equality is value-based across all fields', () {
      final a = RecordedTraffic(id: 'id-a', missionId: 'ref-1', llmCallCount: 10, toolCallCount: 10, recordedAt: 10);
      final b = RecordedTraffic(id: 'id-a', missionId: 'ref-1', llmCallCount: 10, toolCallCount: 10, recordedAt: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('RecordedTraffic inequality differs when a field changes', () {
      final a = RecordedTraffic(id: 'id-a', missionId: 'ref-1', llmCallCount: 10, toolCallCount: 10, recordedAt: 10);
      final b = RecordedTraffic(id: 'id-b', missionId: 'ref-2', llmCallCount: 20, toolCallCount: 20, recordedAt: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - RecordedTraffic clean-arch layers', () {
    test('RecordedTrafficProvider is a RecordedTrafficService', () {
      final provider = RecordedTrafficProvider();
      expect(provider, isA<RecordedTrafficService>());
    });

    test('RecordedTrafficProvider.current throws UnimplementedError on NoParams', () {
      final provider = RecordedTrafficProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('RecordedTrafficProvider.count throws UnimplementedError on NoParams', () {
      final provider = RecordedTrafficProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
