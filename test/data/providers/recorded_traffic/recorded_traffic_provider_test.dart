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

    test('RecordedTrafficProvider.current returns the active traffic snapshot', () async {
      final traffic = await RecordedTrafficProvider().current(NoParams());
      expect(traffic, isA<RecordedTraffic>());
      expect(traffic.id, 'default');
      expect(traffic.missionId, 'mission-1');
      expect(traffic.llmCallCount, 0);
      expect(traffic.toolCallCount, 0);
    });

    test('RecordedTrafficProvider.current honors an injected snapshot', () async {
      final injected = const RecordedTraffic(
        id: 'rt-1',
        missionId: 'ref-7',
        llmCallCount: 12,
        toolCallCount: 4,
        recordedAt: 999,
      );
      final traffic = await RecordedTrafficProvider(injected).current(NoParams());
      expect(traffic, same(injected));
    });

    test('RecordedTrafficProvider.count returns 1', () async {
      expect(await RecordedTrafficProvider().count(NoParams()), 1);
    });
  });
}
