// Tests for sealed hierarchy deserialization (T007) and typed entity
// properties (T008).
//
// These are integration-glue tests that exercise zfa-generated entities
// through the hand-written sealed class wrappers in types.dart.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 1, 15, 12, 0, 0);
  String ts(DateTime dt) => dt.toIso8601String();

  // ─── T007: ContentBlock deserialization ────────────────────────────────
  group('ContentBlock deserialization', () {
    test('TextBlock.fromJson', () {
      final block = ContentBlock.fromJson({'_type': 'text', 'text': 'hello'});
      expect(block, isA<TextBlock>());
      expect((block as TextBlock).text, 'hello');
    });

    test('ImageBlock.fromJson', () {
      final block = ContentBlock.fromJson({
        '_type': 'image',
        'data': 'base64data',
        'mimeType': 'image/png',
      });
      expect(block, isA<ImageBlock>());
      final img = block as ImageBlock;
      expect(img.data, 'base64data');
      expect(img.mimeType, 'image/png');
    });

    test('AudioBlock.fromJson with duration', () {
      final block = ContentBlock.fromJson({
        '_type': 'audio',
        'data': 'audiodata',
        'mimeType': 'audio/mp3',
        'durationMs': 5000,
      });
      expect(block, isA<AudioBlock>());
      expect((block as AudioBlock).durationMs, 5000);
    });

    test('AudioBlock.fromJson without optional durationMs', () {
      final block = ContentBlock.fromJson({
        '_type': 'audio',
        'data': 'audiodata',
        'mimeType': 'audio/mp3',
      }) as AudioBlock;
      expect(block.durationMs, isNull);
    });

    test('DocumentBlock.fromJson', () {
      final block = ContentBlock.fromJson({
        '_type': 'document',
        'data': 'docdata',
        'mimeType': 'application/pdf',
        'title': 'report',
      });
      expect(block, isA<DocumentBlock>());
      final doc = block as DocumentBlock;
      expect(doc.data, 'docdata');
      expect(doc.title, 'report');
    });

    test('DocumentBlock.fromJson without optional title', () {
      final block = ContentBlock.fromJson({
        '_type': 'document',
        'data': 'docdata',
        'mimeType': 'application/pdf',
      }) as DocumentBlock;
      expect(block.title, isNull);
    });

    test('ToolCallBlock.fromJson', () {
      final block = ContentBlock.fromJson({
        '_type': 'toolCall',
        'id': 'tc_1',
        'name': 'search',
        'arguments': {'query': 'test'},
      });
      expect(block, isA<ToolCallBlock>());
      final tc = block as ToolCallBlock;
      expect(tc.id, 'tc_1');
      expect(tc.name, 'search');
      expect(tc.arguments, {'query': 'test'});
    });

    test('ToolCallBlock.fromJson accepts tool_call type key', () {
      final block = ContentBlock.fromJson({
        'type': 'tool_call',
        'id': 'tc_2',
        'name': 'read',
        'arguments': <String, dynamic>{},
      });
      expect(block, isA<ToolCallBlock>());
    });

    test('ThinkingBlock.fromJson', () {
      final block = ContentBlock.fromJson({
        '_type': 'thinking',
        'thinking': 'reasoning text',
        'signature': 'sig123',
      });
      expect(block, isA<ThinkingBlock>());
      expect((block as ThinkingBlock).signature, 'sig123');
    });

    test('ThinkingBlock.fromJson without optional signature', () {
      final block = ContentBlock.fromJson({
        '_type': 'thinking',
        'thinking': 'reasoning text',
      }) as ThinkingBlock;
      expect(block.signature, isNull);
    });

    test('ContentBlock.fromJson throws on unknown type', () {
      expect(
        () => ContentBlock.fromJson({'_type': 'unknown'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── T007: ContentBlock round-trip ─────────────────────────────────────
  group('ContentBlock round-trip', () {
    test('TextBlock', () {
      const original = TextBlock('hello world');
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });

    test('ImageBlock', () {
      const original = ImageBlock(data: 'd', mimeType: 'image/png');
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });

    test('AudioBlock', () {
      const original = AudioBlock(
        data: 'd',
        mimeType: 'audio/mp3',
        durationMs: 1000,
      );
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });

    test('DocumentBlock', () {
      const original = DocumentBlock(
        data: 'd',
        mimeType: 'application/pdf',
        title: 't',
      );
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });

    test('ToolCallBlock', () {
      final original = ToolCallBlock(
        id: 'tc_1',
        name: 'search',
        arguments: {'q': 'test'},
      );
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });

    test('ThinkingBlock', () {
      const original = ThinkingBlock(thinking: 'r', signature: 's');
      expect(ContentBlock.fromJson(original.toJson()), equals(original));
    });
  });

  // ─── T007: AgentMessage deserialization ────────────────────────────────
  group('AgentMessage deserialization', () {
    test('UserMessage.fromJson with list content', () {
      final msg = AgentMessage.fromJson({
        'role': 'user',
        'content': [
          {'_type': 'text', 'text': 'hi'},
        ],
        'timestamp': ts(fixedTime),
      });
      expect(msg, isA<UserMessage>());
      expect((msg as UserMessage).content, hasLength(1));
    });

    test('UserMessage.fromJson with string content', () {
      final msg = AgentMessage.fromJson({
        'role': 'user',
        'content': 'hello',
        'timestamp': ts(fixedTime),
      }) as UserMessage;
      expect(msg.content.first, isA<TextBlock>());
      expect((msg.content.first as TextBlock).text, 'hello');
    });

    test('UserMessage.fromJson with empty content', () {
      final msg = AgentMessage.fromJson({
        'role': 'user',
        'timestamp': ts(fixedTime),
      }) as UserMessage;
      expect(msg.content, isEmpty);
    });

    test('AssistantMessage.fromJson', () {
      final msg = AgentMessage.fromJson({
        'role': 'assistant',
        'content': [
          {'_type': 'text', 'text': 'response'},
        ],
        'timestamp': ts(fixedTime),
      });
      expect(msg, isA<AssistantMessage>());
    });

    test('ToolResultMessage.fromJson', () {
      final msg = AgentMessage.fromJson({
        'role': 'toolResult',
        'toolCallId': 'tc_1',
        'toolName': 'search',
        'content': 'result data',
        'isError': false,
        'artifactRefs': <Map<String, dynamic>>[],
        'timestamp': ts(fixedTime),
      }) as ToolResultMessage;
      expect(msg.toolCallId, 'tc_1');
      expect(msg.toolName, 'search');
      expect(msg.content, 'result data');
      expect(msg.isError, isFalse);
    });

    test('ToolResultMessage.fromJson accepts tool_result key', () {
      expect(
        AgentMessage.fromJson({
          'role': 'tool_result',
          'toolCallId': 'tc_1',
          'toolName': 'search',
          'content': 'ok',
          'timestamp': ts(fixedTime),
        }),
        isA<ToolResultMessage>(),
      );
    });

    test('CustomMessage.fromJson', () {
      final msg = AgentMessage.fromJson({
        'role': 'custom',
        'messageType': 'status',
        'payload': {'key': 'value'},
        'timestamp': ts(fixedTime),
      }) as CustomMessage;
      expect(msg.messageType, 'status');
      expect(msg.payload, {'key': 'value'});
    });

    test('AgentMessage.fromJson throws on unknown role', () {
      expect(
        () => AgentMessage.fromJson({
          'role': 'unknown',
          'timestamp': ts(fixedTime),
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── T007: AgentMessage round-trip ────────────────────────────────────
  group('AgentMessage round-trip', () {
    test('UserMessage preserves content', () {
      final original = UserMessage.text('hello');
      final restored = AgentMessage.fromJson(original.toJson()) as UserMessage;
      expect(restored.content, hasLength(1));
      expect((restored.content.first as TextBlock).text, 'hello');
    });

    test('AssistantMessage preserves content', () {
      final original = AssistantMessage.text('response');
      final restored =
          AgentMessage.fromJson(original.toJson()) as AssistantMessage;
      expect((restored.content.first as TextBlock).text, 'response');
    });

    test('ToolResultMessage preserves fields', () {
      final original = ToolResultMessage(
        toolCallId: 'tc_1',
        toolName: 'read',
        content: 'file content',
      );
      final restored =
          AgentMessage.fromJson(original.toJson()) as ToolResultMessage;
      expect(restored.toolCallId, 'tc_1');
      expect(restored.toolName, 'read');
      expect(restored.content, 'file content');
      expect(restored.isError, isFalse);
    });

    test('CustomMessage preserves fields', () {
      final original = CustomMessage(
        messageType: 'ping',
        payload: {'ts': 123},
      );
      final restored =
          AgentMessage.fromJson(original.toJson()) as CustomMessage;
      expect(restored.messageType, 'ping');
      expect(restored.payload, {'ts': 123});
    });
  });

  // ─── T007: SessionTreeEntry deserialization ────────────────────────────
  group('SessionTreeEntry deserialization', () {
    test('MessageEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'message',
        'id': 'e_1',
        'parentId': null,
        'timestamp': ts(fixedTime),
        'message': {
          'role': 'user',
          'content': 'hi',
          'timestamp': ts(fixedTime),
        },
      });
      expect(entry, isA<MessageEntry>());
      expect(entry.id, 'e_1');
    });

    test('TurnRecordEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'turn',
        'id': 'e_2',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'tr_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'turnNumber': 1,
          'messageEntryIds': <String>[],
          'toolInvocationEntryIds': <String>[],
          'stopReason': 'endTurn',
          'startedAt': ts(fixedTime),
          'endedAt': ts(fixedTime),
          'durationMs': 100,
        },
      });
      expect(entry, isA<TurnRecordEntry>());
    });

    test('TurnRecordEntry accepts turnRecord type key', () {
      final entry = SessionTreeEntry.fromJson({
        'type': 'turnRecord',
        'id': 'e_2',
        'parentId': null,
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'tr_1',
          'timestamp': ts(fixedTime),
          'turnNumber': 1,
          'messageEntryIds': <String>[],
          'toolInvocationEntryIds': <String>[],
          'stopReason': 'endTurn',
          'startedAt': ts(fixedTime),
          'endedAt': ts(fixedTime),
          'durationMs': 50,
        },
      });
      expect(entry, isA<TurnRecordEntry>());
    });

    test('ToolInvocationEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'toolInvocation',
        'id': 'e_3',
        'parentId': 'e_2',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'ti_1',
          'parentId': 'e_2',
          'timestamp': ts(fixedTime),
          'toolCallId': 'tc_1',
          'toolName': 'search',
          'isError': false,
          'durationMs': 200,
        },
        'arguments': {'q': 'test'},
        'artifactRefs': <Map<String, dynamic>>[],
      });
      expect(entry, isA<ToolInvocationEntry>());
    });

    test('UsageEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'usage',
        'id': 'e_4',
        'parentId': 'e_2',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'ul_1',
          'parentId': 'e_2',
          'timestamp': ts(fixedTime),
          'callId': 'c_1',
          'turnNumber': 1,
          'inputTokens': 100,
          'outputTokens': 50,
          'cacheReadTokens': 0,
          'cacheWriteTokens': 0,
        },
        'model': {
          'provider': 'openai',
          'modelId': 'gpt-4',
          'contextWindow': 8192,
        },
      });
      expect(entry, isA<UsageEntry>());
    });

    test('CompactionTreeEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'compaction',
        'id': 'e_5',
        'parentId': 'e_2',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'ce_1',
          'parentId': 'e_2',
          'timestamp': ts(fixedTime),
          'firstKeptEntryId': 'e_3',
          'tokensBefore': 5000,
          'tokensAfter': 1000,
        },
        'summary': {
          'decisions': <String>[],
          'toolNames': <String>[],
          'keyResults': <String>[],
        },
      });
      expect(entry, isA<CompactionTreeEntry>());
    });

    test('ThinkingLevelEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'thinkingLevel',
        'id': 'e_6',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'tl_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'thinkingLevel': 'high',
        },
      });
      expect(entry, isA<ThinkingLevelEntry>());
    });

    test('ModelChangeTreeEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'modelChange',
        'id': 'e_7',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'mc_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'modelId': 'gpt-4o',
          'provider': 'openai',
        },
      });
      expect(entry, isA<ModelChangeTreeEntry>());
    });

    test('BranchSummaryTreeEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'branchSummary',
        'id': 'e_8',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'bs_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'summary': 'explore alternative',
        },
      });
      expect(entry, isA<BranchSummaryTreeEntry>());
    });

    test('LabelTreeEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'label',
        'id': 'e_9',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'lb_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'label': 'milestone',
        },
      });
      expect(entry, isA<LabelTreeEntry>());
    });

    test('CustomTreeEntry.fromJson', () {
      final entry = SessionTreeEntry.fromJson({
        '_type': 'custom',
        'id': 'e_10',
        'parentId': 'e_1',
        'timestamp': ts(fixedTime),
        'record': {
          'id': 'cx_1',
          'parentId': 'e_1',
          'timestamp': ts(fixedTime),
          'customType': 'checkpoint',
          'payload': '{"x":1}',
        },
      });
      expect(entry, isA<CustomTreeEntry>());
    });

    test('SessionTreeEntry.fromJson throws on unknown type', () {
      expect(
        () => SessionTreeEntry.fromJson({
          '_type': 'unknown',
          'id': 'e_x',
          'timestamp': ts(fixedTime),
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── T007: SessionTreeEntry round-trip ────────────────────────────────
  group('SessionTreeEntry round-trip', () {
    test('MessageEntry preserves id and message', () {
      final original = MessageEntry(
        id: 'e_1',
        parentId: null,
        timestamp: fixedTime,
        message: UserMessage.text('hello'),
      );
      final restored =
          SessionTreeEntry.fromJson(original.toJson()) as MessageEntry;
      expect(restored.id, 'e_1');
      expect(restored.parentId, isNull);
      final userMsg = restored.message as UserMessage;
      expect(userMsg.content.first, isA<TextBlock>());
    });
  });

  // ─── T008: TurnRecord typed properties ─────────────────────────────────
  group('TurnRecord typed properties', () {
    TurnRecord makeRecord({int turnNumber = 1}) {
      final now = DateTime.utc(2026, 1, 15);
      return TurnRecord(
        id: 'tr_1',
        parentId: 'e_0',
        timestamp: now,
        turnNumber: turnNumber,
        messageEntryIds: const ['e_1', 'e_2'],
        toolInvocationEntryIds: const ['e_3'],
        stopReason: 'endTurn',
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 2)),
        durationMs: 2000,
      );
    }

    test('construction and field access', () {
      final record = makeRecord();
      expect(record.id, 'tr_1');
      expect(record.parentId, 'e_0');
      expect(record.turnNumber, 1);
      expect(record.messageEntryIds, ['e_1', 'e_2']);
      expect(record.toolInvocationEntryIds, ['e_3']);
      expect(record.stopReason, 'endTurn');
      expect(record.durationMs, 2000);
    });

    test('copyWith creates new instance with overrides', () {
      final updated = makeRecord().copyWith(turnNumber: 2, durationMs: 500);
      expect(updated.turnNumber, 2);
      expect(updated.durationMs, 500);
      expect(updated.id, 'tr_1');
    });

    test('equality and hashCode', () {
      final a = makeRecord();
      final b = makeRecord();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toJson produces expected keys', () {
      final json = makeRecord().toJson();
      expect(json['id'], 'tr_1');
      expect(json['turnNumber'], 1);
      expect(json['stopReason'], 'endTurn');
      expect(json['durationMs'], 2000);
    });
  });

  // ─── T008: ToolInvocationRecord typed properties ──────────────────────
  group('ToolInvocationRecord typed properties', () {
    ToolInvocationRecord makeRecord({bool isError = false}) {
      return ToolInvocationRecord(
        id: 'ti_1',
        parentId: 'e_0',
        timestamp: DateTime.utc(2026, 1, 15),
        toolCallId: 'tc_1',
        toolName: 'search',
        resultEntryId: 'e_5',
        isError: isError,
        durationMs: 150,
      );
    }

    test('construction and field access', () {
      final record = makeRecord();
      expect(record.id, 'ti_1');
      expect(record.toolCallId, 'tc_1');
      expect(record.toolName, 'search');
      expect(record.resultEntryId, 'e_5');
      expect(record.isError, isFalse);
      expect(record.durationMs, 150);
    });

    test('nullable resultEntryId defaults to null', () {
      final record = ToolInvocationRecord(
        id: 'ti_2',
        timestamp: DateTime.utc(2026, 1, 15),
        toolCallId: 'tc_2',
        toolName: 'read',
        isError: false,
        durationMs: 0,
      );
      expect(record.resultEntryId, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = makeRecord().copyWith(isError: true, durationMs: 200);
      expect(updated.isError, isTrue);
      expect(updated.durationMs, 200);
      expect(updated.toolName, 'search');
    });

    test('equality and hashCode', () {
      expect(makeRecord(), equals(makeRecord()));
      expect(makeRecord().hashCode, equals(makeRecord().hashCode));
    });
  });

  // ─── T008: UsageLedgerEntry typed properties ──────────────────────────
  group('UsageLedgerEntry typed properties', () {
    UsageLedgerEntry makeEntry({int inputTokens = 1000}) {
      return UsageLedgerEntry(
        id: 'ul_1',
        parentId: 'e_0',
        timestamp: DateTime.utc(2026, 1, 15),
        callId: 'c_1',
        turnNumber: 3,
        inputTokens: inputTokens,
        outputTokens: 500,
        cacheReadTokens: 200,
        cacheWriteTokens: 50,
      );
    }

    test('construction and field access', () {
      final entry = makeEntry();
      expect(entry.id, 'ul_1');
      expect(entry.callId, 'c_1');
      expect(entry.turnNumber, 3);
      expect(entry.inputTokens, 1000);
      expect(entry.outputTokens, 500);
      expect(entry.cacheReadTokens, 200);
      expect(entry.cacheWriteTokens, 50);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = makeEntry().copyWith(inputTokens: 200);
      expect(updated.inputTokens, 200);
      expect(updated.outputTokens, 500);
      expect(updated.callId, 'c_1');
    });

    test('equality and hashCode', () {
      expect(makeEntry(), equals(makeEntry()));
      expect(makeEntry().hashCode, equals(makeEntry().hashCode));
    });

    test('toJson produces expected keys', () {
      final json = makeEntry().toJson();
      expect(json['id'], 'ul_1');
      expect(json['callId'], 'c_1');
      expect(json['inputTokens'], 1000);
      expect(json['outputTokens'], 500);
    });

    test('fromJson round-trip', () {
      final entry = makeEntry();
      final restored = UsageLedgerEntry.fromJson(entry.toJson());
      expect(restored, equals(entry));
    });

    test('full round-trip preserves all fields', () {
      final entry = UsageLedgerEntry(
        id: 'ul_1',
        parentId: 'e_0',
        timestamp: DateTime.utc(2026, 1, 15),
        callId: 'c_1',
        turnNumber: 2,
        inputTokens: 500,
        outputTokens: 250,
        cacheReadTokens: 100,
        cacheWriteTokens: 25,
      );
      final restored = UsageLedgerEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.parentId, entry.parentId);
      expect(restored.callId, entry.callId);
      expect(restored.turnNumber, entry.turnNumber);
      expect(restored.inputTokens, entry.inputTokens);
      expect(restored.outputTokens, entry.outputTokens);
      expect(restored.cacheReadTokens, entry.cacheReadTokens);
      expect(restored.cacheWriteTokens, entry.cacheWriteTokens);
    });
  });

  // ─── T008: AgentMessage field comparisons ───────────────────────────────
  group('AgentMessage field comparisons', () {
    test('UserMessage fields match after construction', () {
      final msg = UserMessage.text('hello');
      expect(msg.content, hasLength(1));
      expect((msg.content.first as TextBlock).text, 'hello');
    });

    test('AssistantMessage fields match after construction', () {
      final msg = AssistantMessage.text('reply');
      expect(msg.content, hasLength(1));
      expect((msg.content.first as TextBlock).text, 'reply');
    });

    test('ToolResultMessage fields match', () {
      final msg = ToolResultMessage(
        toolCallId: 'tc_1',
        toolName: 'read',
        content: 'data',
        isError: true,
      );
      expect(msg.toolCallId, 'tc_1');
      expect(msg.toolName, 'read');
      expect(msg.content, 'data');
      expect(msg.isError, isTrue);
    });
  });

  // ─── T008: ContentBlock equality ──────────────────────────────────────
  group('ContentBlock equality', () {
    test('TextBlock equality', () {
      expect(const TextBlock('a'), equals(const TextBlock('a')));
      expect(const TextBlock('a'), isNot(equals(const TextBlock('b'))));
    });

    test('ImageBlock equality', () {
      const a = ImageBlock(data: 'd', mimeType: 'image/png');
      const b = ImageBlock(data: 'd', mimeType: 'image/png');
      const c = ImageBlock(data: 'd', mimeType: 'image/jpeg');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('ToolCallBlock equality compares id and name', () {
      final a = ToolCallBlock(id: '1', name: 'n', arguments: {'a': 1});
      final b = ToolCallBlock(id: '1', name: 'n', arguments: {'a': 2});
      expect(a, equals(b));
    });
  });
}
