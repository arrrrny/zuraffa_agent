// Tests for the playbook-as-spec resolution — issue arrrrny/zuraffa_agent#6
// requirement 3 ("ZikZak playbooks … become an instance of agent specs — one
// mechanism, two uses") and spec 005 US3 acceptance scenario 7 / SC-004:
// "Given a country playbook YAML, When loaded as a spec, Then agent behavior
// changes with no code change."
//
// PR #105 (spec 104) shipped the playbook mechanism itself — steering,
// gating, and response shaping through PlaybookRuntime. This file pins the
// OTHER half of R5.3: the SAME document resolves INTO the existing
// declarative agent-spec machinery (SubAgentSpec, spec 036) — the surface
// the dispatch runtime (spec 070) consumes for named agent types, tool
// allowlists, budgets, and risk tiers — so a country playbook instantiates
// spec-driven sub-agents with zero code change.
//
// TDD: the red run fails on the missing resolution API; the green commit
// adds ONLY a pure-domain extension — no existing file is edited, so the
// neighbouring suites cannot ripple.
//
// Determinism: an injected fixed clock (spec 069 exemplar pattern).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart'
    show RiskTier;
import 'package:zuraffa_agent/src/domain/entities/playbook/playbook_as_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/playbook/playbook_loader.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_spec/sub_agent_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/playbook_runtime.dart';
import 'package:zuraffa_agent/src/engine/sub_agent_dispatch.dart'
    show AllowlistToolDispatcher;
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// Records every dispatch and admits everything (spec 069 exemplar) — the
/// gate under test asserts against what the INNER dispatcher saw.
class RecordingToolDispatcher implements ToolDispatcher {
  final List<String> calls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    calls.add(toolName);
    return ToolDispatchResult(
      success: true,
      result: 'ok:$toolName',
      error: '',
      artifactRefs: const [],
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => [
    for (final call in calls)
      await dispatch(
        toolName: call.toolName,
        arguments: call.arguments,
        isInternalMission: isInternalMission,
      ),
  ];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

/// The Germany country playbook document (allowlist gate) — the same
/// document shape the spec 104 acceptance suite steers missions with.
const _deYaml = '''
id: pb-de-001
name: germany
description: Country playbook for Germany market missions
domain: country
country: DE
steering:
  - content: Greet in German.
  - content: Cite GDPR for personal data.
toolGating:
  mode: allowlist
  allowed: [search, fetch]
response:
  language: de
  maxChars: 120
''';

/// The Japan country playbook document (blocklist gate).
const _jpYaml = '''
id: pb-jp-001
name: japan
description: Country playbook for Japan market missions
domain: country
country: JP
steering:
  - content: Greet in Japanese.
toolGating:
  mode: blocklist
  blocked: [search]
response:
  language: jp
  maxChars: 80
''';

/// A third, novel country playbook document — nothing in the engine knows
/// about France; resolving it proves a playbook becomes a spec instance with
/// only the document (FR-006, no code change).
const _frYaml = '''
id: pb-fr-001
name: france
description: Country playbook for France market missions
steering:
  - content: Answer in French market idiom.
toolGating:
  mode: allowlist
  allowed: [translate]
response:
  maxChars: 200
''';

void main() {
  final loader = PlaybookLoader();
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  group('spec 005 US3 scenario 7 (R5.3) — country playbook loaded AS A '
      'SPEC, issue #6', () {
    test('A7: the Germany document resolves to a SubAgentSpec instance — '
        'steering as the system prompt, allowlist as the tools', () {
      final spec = loader.loadYaml(_deYaml).toSubAgentSpec();

      expect(spec, isA<SubAgentSpec>());
      // The steering text IS the behavior directive the spec-driven
      // agent runs under, in document order, plus the pinned language
      // directive (parity with the runtime's injected steering, U5).
      expect(
        spec.systemPrompt,
        "Greet in German.\nCite GDPR for personal data.\n"
        "[playbook:pb-de-001] Respond in language 'de'.",
      );
      // The gate's allowlist IS the spec's tool allowlist.
      expect(spec.tools, ['search', 'fetch']);
    });

    test('A8: the resolved spec drives the EXISTING dispatch boundary — '
        'behavior follows the document with zero code change', () async {
      final de = loader.loadYaml(_deYaml).toSubAgentSpec();
      final fr = loader.loadYaml(_frYaml).toSubAgentSpec();

      // The SAME boundary code, wired ONLY from each resolved spec.
      final deInner = RecordingToolDispatcher();
      final deBoundary = AllowlistToolDispatcher(
        inner: deInner,
        allowlist: de.tools.toSet(),
      );
      final frInner = RecordingToolDispatcher();
      final frBoundary = AllowlistToolDispatcher(
        inner: frInner,
        allowlist: fr.tools.toSet(),
      );

      // Germany admits search and refuses shell…
      final deSearch = await deBoundary.dispatch(
        toolName: 'search',
        arguments: const {'q': 'markets'},
        isInternalMission: false,
      );
      expect(deSearch.success, isTrue);
      expect(deInner.calls, ['search']);
      final deShell = await deBoundary.dispatch(
        toolName: 'shell',
        arguments: const {'cmd': 'ls'},
        isInternalMission: false,
      );
      expect(deShell.success, isFalse);
      expect(deShell.error, 'tool not allowed: shell');
      expect(deInner.calls, ['search']);

      // …while France — a NOVEL document, not one line of code changed —
      // admits translate and refuses BOTH shell and search.
      final frTranslate = await frBoundary.dispatch(
        toolName: 'translate',
        arguments: const {'q': 'marchés'},
        isInternalMission: false,
      );
      expect(frTranslate.success, isTrue);
      final frShell = await frBoundary.dispatch(
        toolName: 'shell',
        arguments: const {'cmd': 'ls'},
        isInternalMission: false,
      );
      expect(frShell.success, isFalse);
      final frSearch = await frBoundary.dispatch(
        toolName: 'search',
        arguments: const {'q': 'markets'},
        isInternalMission: false,
      );
      expect(frSearch.success, isFalse);
      expect(frInner.calls, ['translate']);
    });

    test('U5: one document, two uses — the spec system prompt carries the '
        'same directives the runtime injects as steering', () {
      final playbook = loader.loadYaml(_deYaml);
      final spec = playbook.toSubAgentSpec();
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);

      final injected = [
        for (final message in runtime.steeringMessages()) message.content,
      ];
      expect(injected, hasLength(3));
      for (final directive in injected) {
        expect(spec.systemPrompt, contains(directive));
      }
    });

    test('U1: identity mapping — the document id is the spec name, the '
        'description carries, risk tier defaults safe, budgets inherit', () {
      final spec = loader.loadYaml(_deYaml).toSubAgentSpec();

      expect(spec.name, 'pb-de-001');
      expect(spec.description, 'Country playbook for Germany market missions');
      expect(spec.riskTier, RiskTier.safe);
      // The playbook schema carries no budgets (spec 104) — the resolved
      // instance inherits, per spec 036's null-means-inherit contract.
      expect(spec.maxTurns, isNull);
      expect(spec.wallClockTimeout, isNull);
      expect(spec.contextWindowTokens, isNull);
      expect(spec.isRoot, isTrue);
      expect(spec.isLeaf, isTrue);
    });

    test('U2: a playbook with no gating section resolves to an EMPTY tool '
        'allowlist — specs are allowlist-native, a no-gate playbook grants '
        'no tools', () {
      const yaml = '''
id: pb-es-001
name: spain
description: Country playbook with no gating section
steering:
  - content: Answer in Spanish.
''';
      final spec = loader.loadYaml(yaml).toSubAgentSpec();

      expect(spec.tools, isEmpty);
      expect(spec.systemPrompt, 'Answer in Spanish.');
    });

    test('U3: a blocklist gate is rejected with an actionable diagnostic', () {
      final playbook = loader.loadYaml(_jpYaml);

      expect(
        () => playbook.toSubAgentSpec(),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('restate the gate as an allowlist'),
          ),
        ),
      );
    });

    test('U4: a steering-less playbook is rejected — nothing resolves into '
        'a system prompt', () {
      const yaml = '''
id: pb-it-001
name: italy
description: Country playbook with no steering entries
''';
      final playbook = loader.loadYaml(yaml);

      expect(
        () => playbook.toSubAgentSpec(),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('no steering'),
          ),
        ),
      );
    });
  });
}
