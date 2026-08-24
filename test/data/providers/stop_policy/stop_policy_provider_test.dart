// Regression test for arrarrny/zuraffa_agent#14.
//
// Asserts the hand-curated StopPolicy clean-architecture layers (repository,
// service, provider) compile and that the override relationships hold.
//
// Background: `zfa make StopPolicy repository usecase di mock provider service
// datasource` crashes for every entity with `type 'bool' is not a subtype of
// type 'String?' in type cast`. The clean-arch layers never emit. This test
// guards the hand-curated replacement that ships in the consuming repo until
// zfa ships the matching fix.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/repositories/stop_policy_repository.dart';
import 'package:zuraffa_agent/src/domain/services/stop_policy_service.dart';
import 'package:zuraffa_agent/src/data/providers/stop_policy/stop_policy_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#14 — StopPolicy clean-arch layers', () {
    test('StopPolicyProvider is a StopPolicyService', () {
      expect(StopPolicyProvider(), isA<StopPolicyService>());
    });

    test('StopPolicyProvider.current throws UnimplementedError on NoParams', () {
      expect(
        () => StopPolicyProvider().current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('StopPolicyProvider.defaultPolicy throws UnimplementedError on NoParams', () {
      expect(
        () => StopPolicyProvider().defaultPolicy(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    // Sentinel: the StopPolicyService interface is exported and usable as a
    // type bound from the consuming application. If this stops compiling, the
    // service interface was deleted.
    test('StopPolicyService is usable as a type bound', () {
      StopPolicyService mk(StopPolicyService s) => s;
      final provider = StopPolicyProvider();
      expect(mk(provider), same(provider));
    });

    // Sentinel: the StopPolicyRepository interface is exported.
    test('StopPolicyRepository is usable as a type bound', () {
      // Cannot easily construct without an implementation; verify the type
      // can be referenced as a generic bound.
      void fn<T extends StopPolicyRepository>() {}
      // Calling fn<StopPolicyRepository>() compiles only if the type is
      // exported and resolvable.
      fn<StopPolicyRepository>();
      expect(true, isTrue);
    });
  });
}
