// PolicyResolver tests (issue #205 edge cases, contracts/governance-hooks.md).
//
// Two governance policies installed merge deterministically: deny wins over
// allow; the stricter risk tier wins; redaction rules union; approval tiers
// union; the smallest oversized threshold wins. The merge is recorded, never
// a silent pick.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

GovernancePolicy _policy({
  required String id,
  List<String> allow = const [],
  List<String> deny = const [],
  Map<String, RiskTier> tiers = const {},
  List<RedactionRule> rules = const [],
  List<RiskTier> approval = const [],
  int? threshold,
}) => GovernancePolicy(
  id: id,
  toolAllowList: allow,
  toolDenyList: deny,
  riskTiers: tiers,
  redactionRules: rules,
  requireApprovalForTiers: approval,
  oversizedResultThreshold: threshold,
);

void main() {
  group('PolicyResolver', () {
    test('no policies yields an empty merged policy', () {
      final merged = PolicyResolver().merge(const []);
      expect(merged.toolAllowList, isEmpty);
      expect(merged.toolDenyList, isEmpty);
    });

    test('a single policy round-trips its fields', () {
      final merged = PolicyResolver().merge([
        _policy(id: 'a', allow: ['t1'], tiers: {'t1': RiskTier.high}),
      ]);
      expect(merged.toolAllowList, ['t1']);
      expect(merged.riskTiers['t1'], RiskTier.high);
    });

    test('deny wins over allow across policies', () {
      final merged = PolicyResolver().merge([
        _policy(id: 'a', allow: ['t1', 't2']),
        _policy(id: 'b', deny: ['t1']),
      ]);
      expect(merged.toolDenyList, contains('t1'));
      // t1 is denied even though another policy allowed it.
      expect(PolicyResolver().isDenied(merged, 't1'), isTrue);
      expect(PolicyResolver().isDenied(merged, 't2'), isFalse);
    });

    test('the stricter risk tier wins', () {
      final merged = PolicyResolver().merge([
        _policy(id: 'a', tiers: {'t1': RiskTier.low}),
        _policy(id: 'b', tiers: {'t1': RiskTier.critical}),
      ]);
      expect(merged.riskTiers['t1'], RiskTier.critical);
    });

    test('redaction rules union by name', () {
      final merged = PolicyResolver().merge([
        _policy(
          id: 'a',
          rules: [
            RedactionRule(name: 'email', pattern: r'x@y.z', replacement: 'E'),
          ],
        ),
        _policy(
          id: 'b',
          rules: [
            RedactionRule(name: 'email', pattern: r'a@b.c', replacement: 'E2'),
            RedactionRule(name: 'phone', pattern: r'\d+', replacement: 'P'),
          ],
        ),
      ]);
      expect(
        merged.redactionRules.map((r) => r.name),
        containsAll(['email', 'phone']),
      );
      // first rule wins for a duplicated name (deterministic).
      expect(
        merged.redactionRules.firstWhere((r) => r.name == 'email').pattern,
        r'x@y.z',
      );
    });

    test('approval tiers union and the smallest threshold wins', () {
      final merged = PolicyResolver().merge([
        _policy(id: 'a', approval: [RiskTier.high], threshold: 1000),
        _policy(id: 'b', approval: [RiskTier.critical], threshold: 256),
      ]);
      expect(
        merged.requireApprovalForTiers,
        containsAll([RiskTier.high, RiskTier.critical]),
      );
      expect(merged.oversizedResultThreshold, 256);
    });

    test('default-deny: an unregistered tool is denied', () {
      final merged = PolicyResolver().merge([
        _policy(id: 'a', allow: ['t1']),
      ]);
      expect(PolicyResolver().isDenied(merged, 'unknown'), isTrue);
      expect(PolicyResolver().isDenied(merged, 't1'), isFalse);
    });
  });
}
