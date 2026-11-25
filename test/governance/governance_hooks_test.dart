// Tool governance hook tests (FR-001, FR-002, FR-003, SC-001..SC-003,
// contracts/governance-hooks.md).
//
// Governance rides pi's real hook types: beforeTool denies before execution
// (default-deny), afterTool redacts PII / fails closed / routes oversized
// results, and the provider-request seam (transformContext) scrubs egress.
import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

// Built by concatenation so the key shape never sits contiguously in source
// (GitHub push protection flags the literal fixture).
final awsKey =
    'AK'
    'IA'
    'ABCDEFGHIJKLMNOP';

GovernancePolicy _policy({
  List<String> allow = const [],
  List<String> deny = const [],
  Map<String, RiskTier> tiers = const {},
  List<RiskTier> approval = const [],
  int? threshold,
  List<RedactionRule> rules = const [],
}) => GovernancePolicy(
  id: 'p',
  toolAllowList: allow,
  toolDenyList: deny,
  riskTiers: tiers,
  redactionRules: rules,
  requireApprovalForTiers: approval,
  oversizedResultThreshold: threshold,
);

BeforeToolCallContext _before(
  String tool, [
  Map<String, dynamic> args = const {},
]) => BeforeToolCallContext(
  toolCallId: 'c1',
  toolName: tool,
  args: args,
  overrideArgs: (_) {},
);

AfterToolCallContext _after(String tool, AgentToolResult<dynamic> result) =>
    AfterToolCallContext(
      toolCallId: 'c1',
      toolName: tool,
      args: const {},
      result: result,
    );

AgentToolResult<dynamic> _result(List<ContentBlock> content) =>
    AgentToolResult<dynamic>(content: content, details: null);

void main() {
  group('beforeTool governance', () {
    test('a denied tool is blocked before execution (SC-001)', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final ext = GovernanceExtension.create(
        _policy(allow: ['ok'], deny: ['rm']),
        telemetry: telemetry,
      );
      final result = await ext.beforeToolCall!(_before('rm'));
      expect(result, isNotNull);
      expect(result!.reason, contains('denied'));
      expect(
        telemetry.events.any((e) => e.attributes['outcome'] == 'deny'),
        isTrue,
      );
    });

    test('default-deny blocks an unregistered tool (SC-003)', () async {
      final ext = GovernanceExtension.create(_policy(allow: ['ok']));
      final result = await ext.beforeToolCall!(_before('unknown'));
      expect(result, isNotNull);
      expect(result!.reason, contains('denied'));
    });

    test('an allow-listed tool passes (returns null)', () async {
      final ext = GovernanceExtension.create(_policy(allow: ['ok']));
      final result = await ext.beforeToolCall!(_before('ok'));
      expect(result, isNull);
    });

    test('a high-tier tool gates through the approval port (SC-004)', () async {
      final approvals = InMemoryAgentApprovalPort();
      final ext = GovernanceExtension.create(
        _policy(
          allow: ['deploy'],
          tiers: {'deploy': RiskTier.high},
          approval: [RiskTier.high],
        ),
        telemetry: InMemoryAgentTelemetryPort(),
        approvals: approvals,
      );
      final granted = await ext.beforeToolCall!(_before('deploy'));
      expect(granted, isNull);
      expect(approvals.requests, hasLength(1));

      final deniedApprovals = InMemoryAgentApprovalPort(
        decision: ApprovalDecision.denied,
      );
      final ext2 = GovernanceExtension.create(
        _policy(
          allow: ['deploy'],
          tiers: {'deploy': RiskTier.high},
          approval: [RiskTier.high],
        ),
        approvals: deniedApprovals,
      );
      final denied = await ext2.beforeToolCall!(_before('deploy'));
      expect(denied, isNotNull);
      expect(denied!.reason, contains('approval'));
    });
  });

  group('afterTool governance', () {
    test(
      'a PII-bearing result is redacted before the model (SC-001)',
      () async {
        final telemetry = InMemoryAgentTelemetryPort();
        final ext = GovernanceExtension.create(
          _policy(
            allow: ['t'],
            rules: [
              RedactionRule(
                name: 'email',
                pattern: r'\S+@\S+\.\S+',
                replacement: '[REDACTED:email]',
              ),
            ],
          ),
          telemetry: telemetry,
        );
        final out = await ext.afterToolCall!(
          _after('t', _result([const TextBlock('mail a@b.com now')])),
        );
        expect(out, isNotNull);
        final text = (out!.content!.single as TextBlock).text;
        expect(text, isNot(contains('a@b.com')));
        expect(text, contains('[REDACTED:email]'));
      },
    );

    test(
      'a sanitizer failure fails closed with no unredacted content (SC-002)',
      () async {
        final telemetry = InMemoryAgentTelemetryPort();
        final ext = GovernanceExtension.create(
          _policy(allow: ['t']),
          telemetry: telemetry,
          scrubber: _ThrowingScrubber(),
        );
        final out = await ext.afterToolCall!(
          _after('t', _result([TextBlock('secret $awsKey')])),
        );
        expect(out, isNotNull);
        expect(out!.isError, isTrue);
        final text = (out.content!.single as TextBlock).text;
        expect(text, isNot(contains(awsKey)));
        expect(
          telemetry.events.any((e) => e.attributes['outcome'] == 'failClosed'),
          isTrue,
        );
      },
    );

    test('an oversized result is stored and referenced (SC-007)', () async {
      final artifacts = InMemoryAgentArtifactPort();
      final ext = GovernanceExtension.create(
        _policy(allow: ['t'], threshold: 4),
        artifacts: artifacts,
      );
      final out = await ext.afterToolCall!(
        _after('t', _result([const TextBlock('123456')])),
      );
      expect(out, isNotNull);
      final text = (out!.content!.single as TextBlock).text;
      expect(text, contains('oversized'));
      expect(text, isNot(contains('123456')));
    });

    test(
      'a stored oversized artifact round-trips to the raw text',
      () async {
        final artifacts = InMemoryAgentArtifactPort();
        final ext = GovernanceExtension.create(
          _policy(allow: ['t'], threshold: 4),
          artifacts: artifacts,
        );
        const raw = 'the original tool output';
        final out = await ext.afterToolCall!(
          _after('t', _result([const TextBlock(raw)])),
        );
        final ref = out!.details as AgentArtifactRef;
        final stored = await artifacts.resolve(ref.id);
        expect(utf8.decode(stored!), raw);
        expect(stored, isNot(contains('TextBlock')));
      },
    );
  });

  group('provider-request egress sanitization', () {
    test(
      'transformContext scrubs secret text before egress (FR-001)',
      () async {
        final ext = GovernanceExtension.create(
          _policy(allow: ['t']),
          scrubber: SecretScrubber.defaults(),
        );
        final out = await ext.transformContext!([
          UserMessage.text('key $awsKey'),
        ]);
        final text =
            ((out.single as UserMessage).content.single as TextBlock).text;
        expect(text, isNot(contains(awsKey)));
        expect(text, contains('[REDACTED:aws-access-key-id]'));
      },
    );

    test(
      'a scrubber failure throws (no egress) and records failClosed',
      () async {
        final telemetry = InMemoryAgentTelemetryPort();
        final ext = GovernanceExtension.create(
          _policy(allow: ['t']),
          telemetry: telemetry,
          scrubber: _ThrowingScrubber(),
        );
        expect(
          () => ext.transformContext!([UserMessage.text('x')]),
          throwsA(isA<SecretScrubberError>()),
        );
        expect(
          telemetry.events.any((e) => e.attributes['outcome'] == 'failClosed'),
          isTrue,
        );
      },
    );

    test(
      'a transform with no scrubbed message records allow, not redact',
      () async {
        final telemetry = InMemoryAgentTelemetryPort();
        final ext = GovernanceExtension.create(
          _policy(allow: ['t']),
          telemetry: telemetry,
          scrubber: SecretScrubber.defaults(),
        );
        await ext.transformContext!([UserMessage.text('ordinary text')]);
        final outcomes = telemetry.events
            .where((e) => e.attributes['phase'] == 'provider-request')
            .map((e) => e.attributes['outcome'])
            .toList();
        expect(outcomes, ['allow']);
        expect(
          telemetry.events.single.attributes['redacted'],
          isFalse,
        );
      },
    );

    test(
      'a transform that redacts a message records redact with redacted=true',
      () async {
        final telemetry = InMemoryAgentTelemetryPort();
        final ext = GovernanceExtension.create(
          _policy(allow: ['t']),
          telemetry: telemetry,
          scrubber: SecretScrubber.defaults(),
        );
        await ext.transformContext!([UserMessage.text('key $awsKey')]);
        expect(
          telemetry.events.any(
            (e) =>
                e.attributes['phase'] == 'provider-request' &&
                e.attributes['outcome'] == 'redact' &&
                e.attributes['redacted'] == true,
          ),
          isTrue,
        );
      },
    );
  });
}

/// A [SecretScrubber] whose [scrub] always throws, to exercise fail-closed.
class _ThrowingScrubber extends SecretScrubber {
  _ThrowingScrubber()
    : super(
        rules: [RedactionRule(name: 'x', pattern: r'.*', replacement: 'y')],
      );

  @override
  String scrub(String payload) =>
      throw const SecretScrubberError('forced failure');
}
