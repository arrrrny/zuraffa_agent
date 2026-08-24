// HAND-CURATED regression tests for the GraderSealed value object +
// GraderSealedProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/grader_sealed/grader_sealed.dart';
import 'package:zuraffa_agent/src/domain/services/grader_sealed_service.dart';
import 'package:zuraffa_agent/src/data/providers/grader_sealed/grader_sealed_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - GraderSealed value equality', () {
    test('GraderSealed equality is value-based across all fields', () {
      final a = GraderSealed(id: 'id-a', graderType: 'exact', expectedHash: null, schemaId: null);
      final b = GraderSealed(id: 'id-a', graderType: 'exact', expectedHash: null, schemaId: null);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('GraderSealed inequality differs when a field changes', () {
      final a = GraderSealed(id: 'id-a', graderType: 'exact', expectedHash: null, schemaId: null);
      final b = GraderSealed(id: 'id-b', graderType: 'schema', expectedHash: null, schemaId: null);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - GraderSealed clean-arch layers', () {
    test('GraderSealedProvider is a GraderSealedService', () {
      final provider = GraderSealedProvider();
      expect(provider, isA<GraderSealedService>());
    });

    test('GraderSealedProvider.current throws UnimplementedError on NoParams', () {
      final provider = GraderSealedProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('GraderSealedProvider.count throws UnimplementedError on NoParams', () {
      final provider = GraderSealedProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
