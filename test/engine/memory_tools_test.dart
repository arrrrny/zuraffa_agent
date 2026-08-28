// Tests for the memory tools (spec 074): AgentTool declarations, the
// ToolDispatcher bridge onto AgentMemorySystem (073), and the prompt
// projection.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/engine/agent_memory.dart';
import 'package:zuraffa_agent/src/engine/memory_tools.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

void main() {
  group('spec 074 — MemoryTools', () {
    test('declarations are safe-tier typed tools', () {
      final tools = MemoryTools.declarations;
      expect(tools, hasLength(3));
      expect(tools.map((t) => t.id),
          ['memory_remember', 'memory_recall', 'memory_link']);
      for (final tool in tools) {
        expect(tool.riskTier, RiskTier.safe);
        expect(tool.executionMode, ExecutionMode.sequential);
        expect(tool.description, isNotEmpty);
        expect(tool.paramsSchema, isNotNull);
        expect(tool.requiresConfirmation, isFalse);
      }

      // Schemas declare the required params.
      final remember =
          tools.firstWhere((t) => t.id == 'memory_remember');
      expect(
          (remember.paramsSchema!['required'] as List), contains('content'));
      final recall = tools.firstWhere((t) => t.id == 'memory_recall');
      expect((recall.paramsSchema!['required'] as List), contains('query'));
      final link = tools.firstWhere((t) => t.id == 'memory_link');
      expect((link.paramsSchema!['required'] as List),
          containsAll(['from_id', 'to_id', 'type']));

      expect(() => tools.add(tools.first), throwsUnsupportedError);
    });

    test('remember generates ids and flows arguments', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      final r1 = await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {
          'content': 'the user prefers terse answers',
          'tags': ['preference'],
          'salience': 0.8,
        },
        isInternalMission: false,
      );
      expect(r1.success, isTrue);
      expect(r1.error, isEmpty);
      expect(r1.result, contains('mem-1'));

      final r2 = await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'second note'},
        isInternalMission: false,
      );
      expect(r2.result, contains('mem-2'));

      // Explicit id wins over the counter.
      final r3 = await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'id': 'custom-id', 'content': 'explicit id note'},
        isInternalMission: false,
      );
      expect(r3.result, contains('custom-id'));

      // Arguments flowed into the stored record.
      final stored = memory.longTermMemory.byId('mem-1')!;
      expect(stored.content, 'the user prefers terse answers');
      expect(stored.tags, contains('preference'));
      expect(stored.salience, 0.8);
      expect(stored.source.agentName, 'memory-tool');
    });

    test('remember routes by session_id argument', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'scoped note', 'session_id': 'sess-42'},
        isInternalMission: false,
      );
      expect(memory.sessionMemory.forSession('sess-42'), hasLength(1));
      expect(memory.longTermMemory.all, isEmpty,
          reason: 'session-scoped write must NOT land long-term');

      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'durable note'},
        isInternalMission: false,
      );
      expect(memory.longTermMemory.all, hasLength(1));
      expect(memory.sessionMemory.forSession('sess-42'), hasLength(1),
          reason: 'long-term write must NOT touch the session');
    });

    test('recall renders ranked layer-attributed lines', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'rust borrow checker rules', 'salience': 0.9},
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {
          'content': 'rust async pitfalls',
          'salience': 0.4,
          'session_id': 's1',
        },
        isInternalMission: false,
      );

      final result = await dispatcher.dispatch(
        toolName: 'memory_recall',
        arguments: {'query': 'rust', 'limit': 1},
        isInternalMission: false,
      );
      expect(result.success, isTrue);
      final lines = result.result.split('\n');
      expect(lines, hasLength(1), reason: 'limit honored');
      expect(lines.single, contains('longTerm'));
      expect(lines.single, contains('mem-1'));
      expect(lines.single, contains('salience 0.9'));
      expect(lines.single, contains('rust borrow checker rules'));

      final unbounded = await dispatcher.dispatch(
        toolName: 'memory_recall',
        arguments: {'query': 'rust'},
        isInternalMission: false,
      );
      expect(unbounded.result.split('\n'), hasLength(2));
      expect(unbounded.result, contains('session'));
    });

    test('link validates and delegates to the system', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'id': 'a', 'content': 'claim one'},
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'id': 'b', 'content': 'evidence for claim one'},
        isInternalMission: false,
      );

      final linked = await dispatcher.dispatch(
        toolName: 'memory_link',
        arguments: {
          'from_id': 'b',
          'to_id': 'a',
          'type': 'supports',
          'note': 'b backs a',
        },
        isInternalMission: false,
      );
      expect(linked.success, isTrue);
      expect(linked.result, contains('b'));
      expect(linked.result, contains('a'));
      expect(linked.result, contains('supports'));

      final graphLinks =
          memory.graph.linksOf(MemoryLinkType.supports);
      expect(graphLinks, hasLength(1));
      expect(graphLinks.single.fromRecordId, 'b');
      expect(graphLinks.single.note, 'b backs a');

      // Self-link: failure result, not a throw.
      final self = await dispatcher.dispatch(
        toolName: 'memory_link',
        arguments: {'from_id': 'a', 'to_id': 'a', 'type': 'relatesTo'},
        isInternalMission: false,
      );
      expect(self.success, isFalse);
      expect(self.error, isNotEmpty);
    });

    test('model-shaped failures come back as failure results', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      Future<ToolDispatchOutcome> run(String tool, Map<String, dynamic> args) async {
        final r = await dispatcher.dispatch(
            toolName: tool, arguments: args, isInternalMission: false);
        return (r.success, r.error);
      }

      // Missing content.
      var (ok, err) = await run('memory_remember', {});
      expect(ok, isFalse);
      expect(err, isNotEmpty);

      // Whitespace content.
      (ok, err) = await run('memory_remember', {'content': '   '});
      expect(ok, isFalse);
      expect(err, isNotEmpty);

      // Bad salience.
      (ok, err) = await run(
          'memory_remember', {'content': 'x', 'salience': 2.5});
      expect(ok, isFalse);
      expect(err, isNotEmpty);

      // Unknown tool.
      (ok, err) = await run('memory_teleport', {'content': 'x'});
      expect(ok, isFalse);
      expect(err, contains('memory_teleport'));

      // Empty recall query.
      (ok, err) = await run('memory_recall', {'query': ''});
      expect(ok, isFalse);
      expect(err, isNotEmpty);

      // Unknown link type.
      (ok, err) = await run('memory_link', {
        'from_id': 'a',
        'to_id': 'b',
        'type': 'explodes',
      });
      expect(ok, isFalse);
      expect(err, contains('explodes'));

      // Unknown link endpoint.
      (ok, err) = await run('memory_link', {
        'from_id': 'ghost',
        'to_id': 'b',
        'type': 'supports',
      });
      expect(ok, isFalse);
      expect(err, isNotEmpty);
    });

    test('dispatchBatch maps every call in order', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      final results = await dispatcher.dispatchBatch(
        calls: const [
          ToolCall(
            toolName: 'memory_remember',
            arguments: {'content': 'batch note one'},
            executionMode: 'sequential',
          ),
          ToolCall(
            toolName: 'memory_remember',
            arguments: {'content': 'batch note two'},
            executionMode: 'sequential',
          ),
          ToolCall(
            toolName: 'memory_recall',
            arguments: {'query': 'batch'},
            executionMode: 'sequential',
          ),
        ],
        isInternalMission: false,
      );

      expect(results, hasLength(3));
      expect(results[0].success && results[1].success && results[2].success,
          isTrue);
      expect(results[2].result.split('\n'), hasLength(2));
      expect(memory.longTermMemory.all, hasLength(2));
    });

    test('schema validation and risk tier', () {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      // Missing required keys reported per tool.
      expect(
        dispatcher.validateSchema(
          schema: MemoryTools.rememberTool.paramsSchema!,
          arguments: {'tags': ['x']},
        ),
        isNotEmpty,
      );
      expect(
        dispatcher.validateSchema(
          schema: MemoryTools.rememberTool.paramsSchema!,
          arguments: {'content': 'fine'},
        ),
        isEmpty,
      );
      expect(
        dispatcher.validateSchema(
          schema: MemoryTools.recallTool.paramsSchema!,
          arguments: {},
        ),
        isNotEmpty,
      );
      expect(
        dispatcher.validateSchema(
          schema: MemoryTools.linkTool.paramsSchema!,
          arguments: {'from_id': 'a', 'to_id': 'b', 'type': 'supports'},
        ),
        isEmpty,
      );

      // Memory tools are safe-tier: any risk question is yes.
      expect(
          dispatcher.checkRiskTier(riskTier: 'safe', isInternalMission: false),
          isTrue);
    });

    test('projection ranks by salience and marks session notes', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'low note', 'salience': 0.2},
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'high note', 'salience': 0.9},
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'mid note', 'salience': 0.5},
        isInternalMission: false,
      );

      final projection = MemoryPromptProjection(memory: memory);
      final top2 = projection.render(limit: 2);
      expect(top2, hasLength(2));
      expect(top2.first, contains('high note'));
      expect(top2.last, contains('mid note'));
      expect(top2.first, startsWith('- ['));

      // Session notes: prepended, marked, insertion order.
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'session note one', 'session_id': 'sx'},
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {'content': 'session note two', 'session_id': 'sx'},
        isInternalMission: false,
      );

      final withSession =
          projection.renderWithSession('sx', limit: 2);
      expect(withSession, hasLength(4));
      expect(withSession[0], contains('[session]'));
      expect(withSession[0], contains('session note one'));
      expect(withSession[1], contains('session note two'));
      expect(withSession[2], contains('high note'));

      // Empty memory renders empty.
      expect(
          MemoryPromptProjection(memory: AgentMemorySystem()).render(),
          isEmpty);
    });

    test('agent story: remember, link, recall, project', () async {
      final memory = AgentMemorySystem();
      final dispatcher = MemoryToolDispatcher(memory: memory);

      // The agent remembers a preference (long-term) and today's session
      // note reinforcing it, then links them.
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {
          'id': 'pref',
          'content': 'user prefers dart over kotlin',
          'tags': ['preference'],
          'salience': 0.9,
        },
        isInternalMission: false,
      );
      await dispatcher.dispatch(
        toolName: 'memory_remember',
        arguments: {
          'id': 'today',
          'content': 'user picked dart again today',
          'session_id': 'mission-9',
          'salience': 0.6,
        },
        isInternalMission: false,
      );
      final linkResult = await dispatcher.dispatch(
        toolName: 'memory_link',
        arguments: {
          'from_id': 'today',
          'to_id': 'pref',
          'type': 'supports',
        },
        isInternalMission: false,
      );
      expect(linkResult.success, isTrue);

      // Recall sees both, ranked.
      final recall = await dispatcher.dispatch(
        toolName: 'memory_recall',
        arguments: {'query': 'dart'},
        isInternalMission: false,
      );
      expect(recall.success, isTrue);
      final lines = recall.result.split('\n');
      expect(lines, hasLength(2));
      expect(lines.first, contains('pref'));
      expect(lines.first, contains('longTerm'));

      // The projection surfaces the strongest preference.
      final projection = MemoryPromptProjection(memory: memory);
      expect(projection.render(limit: 1).single, contains('dart over kotlin'));
    });
  });
}

typedef ToolDispatchOutcome = (bool, String);
