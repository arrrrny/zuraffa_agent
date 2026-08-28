// Tests for SubAgentResult value object — Spec 005 (sub-agents & declarative).
//
// Covers:
// - A2: a completed sub-agent result carries a summary (ok == true).
// - A3: a failing sub-agent result is typed (ok == false, failureKind + reason).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_instance/sub_agent_result.dart';

void main() {
  group('spec 005 A2/A3 - SubAgentResult typed outcome', () {
    test('A2: a success result carries a summary and is ok', () {
      final r = SubAgentResult.success(
        instanceId: 'inst-1',
        summary: 'Scanned 12 files, 0 vulnerabilities.',
      );
      expect(r.ok, isTrue);
      expect(r.summary, 'Scanned 12 files, 0 vulnerabilities.');
      expect(r.failureKind, isNull);
      expect(r.failureReason, isNull);
    });

    test('A3: a failure result is typed with a kind and reason, and is not ok', () {
      final r = SubAgentResult.failure(
        instanceId: 'inst-2',
        failureKind: SubAgentFailureKind.toolError,
        failureReason: 'tool read_file denied',
      );
      expect(r.ok, isFalse);
      expect(r.failureKind, SubAgentFailureKind.toolError);
      expect(r.failureReason, 'tool read_file denied');
    });

    test('value equality across fields', () {
      final a = SubAgentResult.failure(
        instanceId: 'i',
        failureKind: SubAgentFailureKind.timeout,
        failureReason: 't',
      );
      final b = SubAgentResult.failure(
        instanceId: 'i',
        failureKind: SubAgentFailureKind.timeout,
        failureReason: 't',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
