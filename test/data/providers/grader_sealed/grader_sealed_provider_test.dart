// HAND-CURATED regression tests for the GraderSealed value object +
// GraderSealedProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/grader_sealed/grader_sealed_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/grader_sealed/grader_sealed.dart';
import 'package:zuraffa_agent/src/domain/services/grader_sealed_service.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - GraderSealed value equality', () {
    test('GraderSealed equality is value-based across all fields', () {
      const a = GraderSealed(
        id: 'id-a',
        graderType: 'exact',
        expectedHash: null,
        schemaId: null,
      );
      const b = GraderSealed(
        id: 'id-a',
        graderType: 'exact',
        expectedHash: null,
        schemaId: null,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('GraderSealed inequality differs when a field changes', () {
      const a = GraderSealed(
        id: 'id-a',
        graderType: 'exact',
        expectedHash: null,
        schemaId: null,
      );
      const b = GraderSealed(
        id: 'id-b',
        graderType: 'schema',
        expectedHash: null,
        schemaId: null,
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - GraderSealed clean-arch layers', () {
    test('GraderSealedProvider is a GraderSealedService', () {
      final provider = GraderSealedProvider();
      expect(provider, isA<GraderSealedService>());
    });

    test(
      'GraderSealedProvider.current returns the active grader snapshot',
      () async {
        final grader = await GraderSealedProvider().current(const NoParams());
        expect(grader, isA<GraderSealed>());
        expect(grader.id, 'default');
        expect(grader.graderType, 'exact');
      },
    );

    test('GraderSealedProvider.current honors an injected snapshot', () async {
      const injected = GraderSealed(id: 'g-1', graderType: 'schema');
      final grader = await GraderSealedProvider(
        injected,
      ).current(const NoParams());
      expect(grader, same(injected));
    });

    test('GraderSealedProvider.count returns 1', () async {
      expect(await GraderSealedProvider().count(const NoParams()), 1);
    });
  });
}
