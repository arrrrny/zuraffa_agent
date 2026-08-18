// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package,
// test/types_test.dart). Source licensed BSD-3-Clause (ZikZak AI);
// modifications licensed MIT under zuraffa_agent.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('ContentBlock sealed class', () {
    test('TextBlock holds text', () {
      const block = TextBlock('hello');
      expect(block.text, 'hello');
    });

    test('ImageBlock holds base64 and mediaType', () {
      const block = ImageBlock(base64Data: 'abc123', mediaType: 'image/png');
      expect(block.base64Data, 'abc123');
      expect(block.mediaType, 'image/png');
    });

    test('AudioBlock holds base64, mediaType and optional transcript', () {
      const block = AudioBlock(base64Data: 'abc', mediaType: 'audio/wav');
      expect(block.mediaType, 'audio/wav');
      expect(block.transcript, isNull);
      const withTranscript = AudioBlock(
          base64Data: 'abc', mediaType: 'audio/wav', transcript: 'hi');
      expect(withTranscript.transcript, 'hi');
    });

    test('DocumentBlock holds mediaType, base64 and optional title', () {
      const block = DocumentBlock(mediaType: 'application/pdf', base64Data: 'abc');
      expect(block.title, isNull);
      const titled = DocumentBlock(
          mediaType: 'application/pdf', base64Data: 'abc', title: 'spec');
      expect(titled.title, 'spec');
    });

    test('ToolCallBlock holds id, name, arguments', () {
      const block = ToolCallBlock(id: 'tc-1', name: 'foo', arguments: {});
      expect(block.id, 'tc-1');
      expect(block.name, 'foo');
    });

    test('ThinkingBlock holds text', () {
      const block = ThinkingBlock('reasoning');
      expect(block.text, 'reasoning');
    });

    test('sealed hierarchy: every block is a ContentBlock', () {
      const blocks = [
        TextBlock('t'),
        ImageBlock(base64Data: 'b', mediaType: 'image/png'),
        AudioBlock(base64Data: 'b', mediaType: 'audio/ogg'),
        DocumentBlock(mediaType: 'text/plain', base64Data: 'b'),
        ToolCallBlock(id: 'i', name: 'n', arguments: {}),
        ThinkingBlock('th'),
      ];
      for (final b in blocks) {
        expect(b, isA<ContentBlock>());
      }
    });
  });

  group('AgentMessage sealed class', () {
    test('UserMessage holds content blocks', () {
      final msg = UserMessage(content: [const TextBlock('hello')]);
      expect(msg.content, hasLength(1));
      expect(switch (msg.content.first) {
        TextBlock(text: final t) => t,
        _ => fail('expected TextBlock'),
      }, 'hello');
    });

    test('UserMessage.text convenience constructor', () {
      final msg = UserMessage.text('hello');
      expect(msg.content, hasLength(1));
      expect(switch (msg.content.first) {
        TextBlock(text: final t) => t,
        _ => fail('expected TextBlock'),
      }, 'hello');
    });

    test('UserMessage multimodal content (text + image + audio + document)',
        () {
      final msg = UserMessage(content: [
        const TextBlock('look at this'),
        const ImageBlock(base64Data: 'img', mediaType: 'image/png'),
        const AudioBlock(base64Data: 'aud', mediaType: 'audio/wav'),
        const DocumentBlock(mediaType: 'application/pdf', base64Data: 'doc'),
      ]);
      expect(msg.content, hasLength(4));
      expect(msg.content[1], isA<ImageBlock>());
      expect(msg.content[2], isA<AudioBlock>());
      expect(msg.content[3], isA<DocumentBlock>());
    });

    test('AssistantMessage holds mixed content', () {
      final msg = AssistantMessage(
        id: 'msg-1',
        content: [
          const TextBlock('hello'),
          const ToolCallBlock(id: 'tc-1', name: 'foo', arguments: {}),
        ],
        stopReason: StopReason.toolUse,
        usage: const Usage(inputTokens: 10, outputTokens: 20),
      );
      expect(msg.id, 'msg-1');
      expect(msg.content, hasLength(2));
      expect(msg.stopReason, StopReason.toolUse);
      expect(msg.usage!.inputTokens, 10);
    });

    test('AssistantMessage.text extracts text', () {
      final msg = AssistantMessage(content: [
        const TextBlock('hello '),
        const TextBlock('world'),
      ]);
      expect(msg.text, 'hello world');
    });

    test('AssistantMessage.toolCalls extracts tool calls', () {
      final msg = AssistantMessage(content: [
        const TextBlock('text'),
        const ToolCallBlock(id: 'tc-1', name: 'foo', arguments: {'a': 1}),
      ]);
      expect(msg.toolCalls, hasLength(1));
      expect(msg.toolCalls.first.name, 'foo');
    });

    test('ToolResultMessage holds result', () {
      final msg = ToolResultMessage(
        toolCallId: 'tc-1',
        toolName: 'foo',
        content: [const TextBlock('result')],
      );
      expect(msg.toolCallId, 'tc-1');
      expect(msg.isError, false);
    });

    test('ToolResultMessage.text convenience constructor', () {
      final msg = ToolResultMessage.text(
        toolCallId: 'tc-1',
        toolName: 'foo',
        text: 'error',
        isError: true,
      );
      expect(msg.isError, true);
      expect(switch (msg.content.first) {
        TextBlock(text: final t) => t,
        _ => fail('expected TextBlock'),
      }, 'error');
    });

    test('CustomMessage holds type and data', () {
      const msg = CustomMessage(type: 'bash', data: {}, display: 'ls');
      expect(msg.type, 'bash');
      expect(msg.display, 'ls');
    });
  });

  group('value equality', () {
    test('blocks compare by value', () {
      expect(const TextBlock('a'), const TextBlock('a'));
      expect(const TextBlock('a'), isNot(const TextBlock('b')));
      expect(
          const ImageBlock(base64Data: 'x', mediaType: 'image/png'),
          const ImageBlock(base64Data: 'x', mediaType: 'image/png'));
      expect(
          const ToolCallBlock(id: '1', name: 'n', arguments: {'k': 'v'}),
          const ToolCallBlock(id: '1', name: 'n', arguments: {'k': 'v'}));
    });

    test('messages compare by value', () {
      expect(UserMessage.text('a'), UserMessage.text('a'));
      expect(UserMessage.text('a'), isNot(UserMessage.text('b')));
      expect(
        AssistantMessage(content: [const TextBlock('t')], stopReason: StopReason.endTurn),
        AssistantMessage(content: [const TextBlock('t')], stopReason: StopReason.endTurn),
      );
      expect(
        ToolResultMessage.text(toolCallId: '1', toolName: 'n', text: 'r'),
        ToolResultMessage.text(toolCallId: '1', toolName: 'n', text: 'r'),
      );
    });

    test('Model and Usage compare by value', () {
      const m1 = Model(provider: 'openai', modelId: 'gpt-4o', contextWindow: 1);
      const m2 = Model(provider: 'openai', modelId: 'gpt-4o', contextWindow: 1);
      expect(m1, m2);
      expect(m1.hashCode, m2.hashCode);
      const u1 = Usage(inputTokens: 1, outputTokens: 2);
      const u2 = Usage(inputTokens: 1, outputTokens: 2);
      expect(u1, u2);
    });
  });

  group('Enums', () {
    test('ThinkingLevel has correct values', () {
      expect(ThinkingLevel.values, [
        ThinkingLevel.off,
        ThinkingLevel.minimal,
        ThinkingLevel.low,
        ThinkingLevel.medium,
        ThinkingLevel.high,
        ThinkingLevel.xhigh,
      ]);
    });

    test('StopReason has correct values', () {
      expect(StopReason.values, [
        StopReason.endTurn,
        StopReason.maxTokens,
        StopReason.toolUse,
        StopReason.stopSequence,
        StopReason.refused,
      ]);
    });

    test('ToolExecutionMode values', () {
      expect(ToolExecutionMode.values,
          [ToolExecutionMode.sequential, ToolExecutionMode.parallel]);
    });
  });

  group('SessionTreeEntry sealed class', () {
    final now = DateTime.utc(2026, 8, 18, 12, 0, 0);

    test('MessageEntry constructs', () {
      final entry = MessageEntry(
        id: '1',
        parentId: '',
        timestamp: now,
        role: 'user',
        message: UserMessage.text('hi'),
      );
      expect(entry.id, '1');
      expect(entry.parentId, '');
      expect(entry.role, 'user');
      expect(entry.timestamp, now);
    });

    test('CompactionEntry holds typed CompactionSummary', () {
      const summary = CompactionSummary(
        decisions: ['switch to hive'],
        toolNames: ['bash'],
        keyResults: ['file found'],
        planState: 'step 2 of 4',
        artifacts: [ArtifactRef(kind: 'tool-output', id: 'a1')],
        prose: 'narrative',
      );
      final entry = CompactionEntry(
        id: '2',
        parentId: '1',
        timestamp: now,
        summary: summary,
        firstKeptEntryId: '3',
        tokensBefore: 1000,
      );
      expect(entry.summary.decisions, ['switch to hive']);
      expect(entry.summary.artifacts.single.kind, 'tool-output');
      expect(entry.tokensBefore, 1000);
    });

    test('switch exhaustiveness covers all subtypes', () {
      String kind(SessionTreeEntry e) => switch (e) {
            MessageEntry() => 'msg',
            ThinkingLevelChangeEntry() => 'thinking',
            ModelChangeEntry() => 'model',
            CompactionEntry() => 'compact',
            BranchSummaryEntry() => 'branch',
            LabelEntry() => 'label',
            CustomEntry() => 'custom',
          };

      final entry = MessageEntry(
          id: '1',
          parentId: '',
          timestamp: now,
          role: 'user',
          message: UserMessage.text(''));
      expect(kind(entry), 'msg');
      expect(
          kind(ThinkingLevelChangeEntry(
              id: '2', parentId: '', timestamp: now, level: ThinkingLevel.low)),
          'thinking');
      expect(
          kind(ModelChangeEntry(
              id: '3', parentId: '', timestamp: now, provider: 'p', modelId: 'm')),
          'model');
      expect(
          kind(BranchSummaryEntry(
              id: '5', parentId: '', timestamp: now, summary: 's')),
          'branch');
      expect(
          kind(LabelEntry(
              id: '6', parentId: '', timestamp: now, targetId: '1', label: 'l')),
          'label');
      expect(
          kind(CustomEntry(
              id: '7', parentId: '', timestamp: now, customType: 't')),
          'custom');
    });

    test('entries compare by value', () {
      final a = MessageEntry(
          id: '1',
          parentId: '',
          timestamp: now,
          role: 'user',
          message: UserMessage.text('x'));
      final b = MessageEntry(
          id: '1',
          parentId: '',
          timestamp: now,
          role: 'user',
          message: UserMessage.text('x'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('entry ID generation', () {
    test('IDs are unique under rapid generation', () {
      final ids = List.generate(10000, (_) => newEntryId()).toSet();
      expect(ids.length, 10000);
    });

    test('IDs are monotonically non-decreasing', () {
      var prev = newEntryId();
      for (var i = 0; i < 1000; i++) {
        final next = newEntryId();
        expect(next.compareTo(prev), greaterThanOrEqualTo(0));
        prev = next;
      }
    });

    test('generation order equals lexicographic order', () {
      final generated = List.generate(500, (_) => newEntryId());
      final sorted = [...generated]..sort();
      expect(sorted, generated);
    });

    test('IDs are fixed width (sortable across processes)', () {
      expect(newEntryId().length, 15);
    });
  });

  group('support types', () {
    test('SessionInfo constructs with defaults', () {
      final now = DateTime.now();
      final info = SessionInfo(id: 's1', name: 'mission', createdAt: now, updatedAt: now);
      expect(info.metadata, isEmpty);
    });

    test('SessionContext constructs', () {
      const ctx = SessionContext(
        messages: [],
        thinkingLevel: ThinkingLevel.high,
        model: Model(provider: 'p', modelId: 'm', contextWindow: 1000),
      );
      expect(ctx.thinkingLevel, ThinkingLevel.high);
    });

    test('CompactionSettings defaults', () {
      const s = CompactionSettings();
      expect(s.enabled, true);
      expect(s.reserveTokens, 16384);
      expect(s.keepRecentTokens, 20000);
      expect(s.triggerThresholdRatio, 1.0);
    });

    test('Skill and SkillDiagnostic construct', () {
      const d = SkillDiagnostic(level: SkillDiagnosticLevel.warning, message: 'm');
      const skill = Skill(
          name: 'n', description: 'd', content: 'c', sourcePath: '/x/SKILL.md');
      expect(skill.hidden, false);
      expect(skill.diagnostics, isEmpty);
      expect(d.level, SkillDiagnosticLevel.warning);
    });

    test('PromptTemplate constructs', () {
      const t = PromptTemplate(
          name: 'n', description: 'd', content: 'c', sourcePath: '/x.md');
      expect(t.args, isEmpty);
    });

    test('AgentToolResult holds content and details', () {
      const r = AgentToolResult<String>(content: [], details: 'x');
      expect(r.terminate, false);
      expect(r.details, 'x');
    });
  });
}
