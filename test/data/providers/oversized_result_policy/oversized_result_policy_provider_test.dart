// HAND-CURATED regression tests for the OversizedResultPolicy value object +
// OversizedResultPolicyProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/oversized_result_policy/oversized_result_policy_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/oversized_result_policy/oversized_result_policy.dart';
import 'package:zuraffa_agent/src/domain/services/oversized_result_policy_service.dart';

void main() {
  group('arrarrny/zuraffa_agent#4 - OversizedResultPolicy value equality', () {
    test('OversizedResultPolicy equality is value-based across all fields', () {
      const a = OversizedResultPolicy(
        id: 'id-a',
        thresholdBytes: 10,
        summaryMaxChars: 10,
        artifactStore: './artifacts',
      );
      const b = OversizedResultPolicy(
        id: 'id-a',
        thresholdBytes: 10,
        summaryMaxChars: 10,
        artifactStore: './artifacts',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('OversizedResultPolicy inequality differs when a field changes', () {
      const a = OversizedResultPolicy(
        id: 'id-a',
        thresholdBytes: 10,
        summaryMaxChars: 10,
        artifactStore: './artifacts',
      );
      const b = OversizedResultPolicy(
        id: 'id-b',
        thresholdBytes: 20,
        summaryMaxChars: 20,
        artifactStore: './artifacts',
      );
      expect(a == b, isFalse);
    });
  });

  group(
    'arrarrny/zuraffa_agent#4 - OversizedResultPolicy clean-arch layers',
    () {
      test(
        'OversizedResultPolicyProvider is a OversizedResultPolicyService',
        () {
          final provider = OversizedResultPolicyProvider();
          expect(provider, isA<OversizedResultPolicyService>());
        },
      );

      test(
        'OversizedResultPolicyProvider.current returns the active policy',
        () async {
          final policy = await OversizedResultPolicyProvider().current(
            const NoParams(),
          );
          expect(policy, isA<OversizedResultPolicy>());
          expect(policy.id, 'default');
          expect(policy.thresholdBytes, greaterThan(0));
          expect(policy.summaryMaxChars, greaterThan(0));
          expect(policy.artifactStore, isNotEmpty);
        },
      );

      test(
        'OversizedResultPolicyProvider honors an injected active policy',
        () async {
          const injected = OversizedResultPolicy(
            id: 'custom',
            thresholdBytes: 1024,
            summaryMaxChars: 128,
            artifactStore: './store',
          );
          final policy = await OversizedResultPolicyProvider(
            injected,
          ).current(const NoParams());
          expect(policy, same(injected));
        },
      );

      test('OversizedResultPolicyProvider.count returns 1', () async {
        expect(
          await OversizedResultPolicyProvider().count(const NoParams()),
          1,
        );
      });
    },
  );
}
