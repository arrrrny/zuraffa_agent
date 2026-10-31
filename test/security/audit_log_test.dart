// Issue arrrrny/zuraffa_agent#132 — AuditLog interface contract.
//
// The audit trail records SECURITY events — provider configuration changes,
// tool-call invocations (as name + argument/result HASHES, never raw
// payloads), approval decisions, and breaker state transitions. Contract
// pinned here:
//
//   - every audited event appends exactly one entry, in call order;
//   - entries carry category + dotted action + detail map; raw argument or
//     result material never appears anywhere in the serialized entry;
//   - argument/result hashes equal auditHash of the canonical JSON, so two
//     calls with equal arguments (any key order) produce equal hashes;
//   - each entry mirrors to one structured log record on the pinned
//     `zuraffa.agent.audit` logger (O-1 delivery discipline: silent unless
//     installed, isLoggable-gated; denial/transition at WARNING per the
//     spec 112 level policy, the rest at INFO);
//   - entry JSON round-trips (equality through the serialized form).

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/src/security/audit_hashing.dart';
import 'package:zuraffa_agent/src/security/audit_log.dart';

import 'in_memory_audit_sink.dart';

void main() {
  late InMemoryAuditSink sink;
  late SinkAuditLog audit;

  setUp(() {
    sink = InMemoryAuditSink();
    var tick = DateTime.utc(2026, 1, 1, 12);
    audit = SinkAuditLog(
      sink: sink,
      clock: () => tick = tick.add(const Duration(milliseconds: 1)),
    );
  });

  tearDown(() {
    ZuraffaLogging.reset();
  });

  group('SinkAuditLog — provider config changes', () {
    test(
      'providerConfigChanged appends one provider.configured entry',
      () async {
        await audit.providerConfigChanged(
          providerId: 'p1',
          providerKind: 'anthropic',
          baseUrl: 'https://api.anthropic.example',
          models: const ['claude-x'],
          timeoutMs: 30000,
          actor: 'host-app',
        );

        expect(sink.stored, hasLength(1));
        final entry = sink.stored.single;
        expect(entry.category, AuditCategory.providerConfig);
        expect(entry.action, AuditActions.providerConfigured);
        expect(entry.details, {
          'providerId': 'p1',
          'providerKind': 'anthropic',
          'baseUrl': 'https://api.anthropic.example',
          'models': ['claude-x'],
          'timeoutMs': 30000,
          'actor': 'host-app',
        });
      },
    );

    test('secret-bearing keys never enter provider details', () async {
      await audit.providerConfigChanged(
        providerId: 'p1',
        providerKind: 'openai',
        baseUrl: 'https://api.openai.example',
        models: const ['gpt'],
        timeoutMs: 1000,
      );
      expect(sink.stored.single.details.keys, isNot(contains('apiKey')));
      expect(sink.stored.single.details.keys, isNot(contains('secret')));
    });
  });

  group('SinkAuditLog — tool call invocations', () {
    test('toolCallInvoked stores hashes, never the raw payload', () async {
      await audit.toolCallInvoked(
        toolName: 'shell',
        arguments: {'cmd': 'ls', 'password': 'hunter2'},
        result: 'SECRET-TOOL-OUTPUT',
        success: true,
        requestId: 'req-1',
      );

      final entry = sink.stored.single;
      expect(entry.category, AuditCategory.toolCall);
      expect(entry.action, AuditActions.toolInvoked);
      expect(entry.details['toolName'], 'shell');
      expect(entry.details['success'], true);
      expect(entry.details['requestId'], 'req-1');
      expect(
        entry.details['argsHash'],
        auditHash({'cmd': 'ls', 'password': 'hunter2'}),
      );
      expect(entry.details['resultHash'], auditHash('SECRET-TOOL-OUTPUT'));

      // The tamper-evidence core: raw material is nowhere in the record.
      final serialized = entry.toJson().toString();
      expect(serialized.contains('hunter2'), isFalse);
      expect(serialized.contains('SECRET-TOOL-OUTPUT'), isFalse);
    });

    test('a null result omits resultHash instead of storing null', () async {
      await audit.toolCallInvoked(
        toolName: 't',
        arguments: const {},
        success: false,
      );
      expect(sink.stored.single.details.containsKey('resultHash'), isFalse);
    });
  });

  group('SinkAuditLog — approval decisions', () {
    test(
      'approve records approval.granted with the request identity',
      () async {
        await audit.approvalDecision(
          requestId: 'apr-1',
          toolName: 'deploy',
          arguments: {'env': 'prod'},
          approved: true,
          actor: 'operator-a',
        );

        final entry = sink.stored.single;
        expect(entry.category, AuditCategory.approval);
        expect(entry.action, AuditActions.approvalGranted);
        expect(entry.details, {
          'requestId': 'apr-1',
          'toolName': 'deploy',
          'argsHash': auditHash({'env': 'prod'}),
          'actor': 'operator-a',
        });
      },
    );

    test('deny records approval.denied', () async {
      await audit.approvalDecision(
        requestId: 'apr-2',
        toolName: 'deploy',
        arguments: const {},
        approved: false,
      );
      expect(sink.stored.single.action, AuditActions.approvalDenied);
    });
  });

  group('SinkAuditLog — breaker transitions', () {
    test('breakerTransition records provider, from and to', () async {
      await audit.breakerTransition(
        providerId: 'p1',
        from: 'closed',
        to: 'open',
      );

      final entry = sink.stored.single;
      expect(entry.category, AuditCategory.breaker);
      expect(entry.action, AuditActions.breakerTransitioned);
      expect(entry.details, {
        'providerId': 'p1',
        'from': 'closed',
        'to': 'open',
      });
    });
  });

  group('SinkAuditLog — trail semantics', () {
    test(
      'every audited event appends exactly one entry, in call order',
      () async {
        await audit.providerConfigChanged(
          providerId: 'p',
          providerKind: 'k',
          baseUrl: 'u',
          models: const [],
          timeoutMs: 1,
        );
        await audit.toolCallInvoked(
          toolName: 't',
          arguments: const {},
          success: true,
        );
        await audit.approvalDecision(
          requestId: 'r',
          toolName: 't',
          arguments: const {},
          approved: false,
        );
        await audit.breakerTransition(providerId: 'p', from: 'a', to: 'b');

        expect(
          [for (final e in sink.stored) e.action],
          [
            AuditActions.providerConfigured,
            AuditActions.toolInvoked,
            AuditActions.approvalDenied,
            AuditActions.breakerTransitioned,
          ],
        );
      },
    );

    test('entry ids are unique; timestamps are UTC and monotonic', () async {
      for (var i = 0; i < 3; i++) {
        await audit.toolCallInvoked(
          toolName: 't$i',
          arguments: const {},
          success: true,
        );
      }
      final ids = sink.stored.map((e) => e.id).toSet();
      expect(ids, hasLength(3));
      expect(sink.stored.map((e) => e.timestamp.isUtc), everyElement(isTrue));
      final stamps = sink.stored.map((e) => e.timestamp).toList();
      expect(stamps[0].isBefore(stamps[1]), isTrue);
      expect(stamps[1].isBefore(stamps[2]), isTrue);
    });

    test('entries serialize to JSON and round-trip', () async {
      await audit.toolCallInvoked(
        toolName: 'shell',
        arguments: {'cmd': 'ls'},
        result: 'out',
        success: true,
        actor: 'engine',
      );

      final entry = sink.stored.single;
      final restored = AuditEntry.fromJson(
        Map<String, dynamic>.from(entry.toJson() as Map),
      );
      expect(restored, entry);
    });
  });

  group('SinkAuditLog — structured logging mirror (O-1)', () {
    test(
      'each audited event emits one record on zuraffa.agent.audit',
      () async {
        final records = MemoryLogSink();
        ZuraffaLogging.install(onRecord: records.add);

        await audit.approvalDecision(
          requestId: 'r',
          toolName: 't',
          arguments: const {},
          approved: true,
        );
        await audit.breakerTransition(
          providerId: 'p',
          from: 'closed',
          to: 'open',
        );

        expect(records.length, 2);
        expect(
          records.records.map((r) => r.loggerName),
          everyElement('zuraffa.agent.audit'),
        );
        expect(records[0].message, contains(AuditActions.approvalGranted));
        expect(records[1].message, contains(AuditActions.breakerTransitioned));
      },
    );

    test(
      'denials and transitions mirror at WARNING, the rest at INFO',
      () async {
        final records = MemoryLogSink();
        ZuraffaLogging.install(onRecord: records.add);

        await audit.approvalDecision(
          requestId: 'r',
          toolName: 't',
          arguments: const {},
          approved: false,
        );
        await audit.toolCallInvoked(
          toolName: 't',
          arguments: const {},
          success: true,
        );
        await audit.breakerTransition(providerId: 'p', from: 'a', to: 'b');

        expect(records[0].level, Level.WARNING); // approval denied
        expect(records[1].level, Level.INFO); // tool invoked
        expect(records[2].level, Level.WARNING); // breaker transition
      },
    );

    test('emission is isLoggable-gated — Level.OFF mirrors nothing', () async {
      final records = MemoryLogSink();
      ZuraffaLogging.install(level: Level.OFF, onRecord: records.add);

      await audit.toolCallInvoked(
        toolName: 't',
        arguments: const {},
        success: true,
      );

      // The durable trail still received the entry…
      expect(sink.stored, hasLength(1));
      // …but no record was mirrored.
      expect(records.length, 0);
    });
  });

  group(
    'SinkAuditLog — a failing sink never throws (issue #132 review fix)',
    () {
      test('every event class survives a throwing sink', () async {
        final failing = SinkAuditLog(
          sink: ThrowingAuditSink(),
          clock: () => DateTime.utc(2026, 1, 1),
        );

        // Reaching the end without an uncaught error IS the contract.
        // Pre-fix, each await rethrew the sink error here; at the consumer
        // seams (fire-and-forget unawaited) the same error instead reached
        // the zone uncaught-error handler.
        await failing.providerConfigChanged(
          providerId: 'p',
          providerKind: 'k',
          baseUrl: 'u',
          models: const [],
          timeoutMs: 1,
        );
        await failing.toolCallInvoked(
          toolName: 't',
          arguments: const {},
          success: true,
        );
        await failing.approvalDecision(
          requestId: 'r',
          toolName: 't',
          arguments: const {},
          approved: false,
        );
        await failing.breakerTransition(providerId: 'p', from: 'a', to: 'b');
      });

      test(
        'the lost entry is mirrored at SEVERE on the audit logger',
        () async {
          final records = MemoryLogSink();
          ZuraffaLogging.install(onRecord: records.add);
          final failing = SinkAuditLog(
            sink: ThrowingAuditSink(),
            clock: () => DateTime.utc(2026, 1, 1),
          );

          await failing.approvalDecision(
            requestId: 'r',
            toolName: 't',
            arguments: const {},
            approved: true,
          );

          final severe = records.firstWhereMessage('audit append failed');
          expect(severe, isNotNull, reason: 'the loss must be logger-visible');
          expect(severe!.level, Level.SEVERE);
          expect(severe.loggerName, 'zuraffa.agent.audit');
          expect(severe.message, contains('approval.granted'));
        },
      );
    },
  );
}
