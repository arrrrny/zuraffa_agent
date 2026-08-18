// Script to generate the 50+ tool-call mission fixture.
// Run with: dart run tool/gen_fixture.dart

import 'dart:convert';
import 'dart:io';

import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  final entries = <Map<String, dynamic>>[];
  final fixedBase = DateTime.utc(2026, 1, 15, 12, 0, 0);
  int seq = 0;

  String nextId() => 'e_${seq++}';

  // Root entry: user message
  entries.add(MessageEntry(
    id: nextId(),
    parentId: null,
    timestamp: fixedBase,
    message: UserMessage.text(
      'Analyze the codebase for security vulnerabilities and generate a report.',
    ),
  ).toJson());

  // 52 tool-call rounds (messages + tool invocations + usage)
  final toolNames = [
    'read_file',
    'search_code',
    'list_directory',
    'write_file',
    'run_tests',
    'grep_pattern',
    'read_file',
    'search_code',
    'read_file',
    'write_file',
  ];

  for (var i = 0; i < 52; i++) {
    final turnStart = fixedBase.add(Duration(seconds: (i + 1) * 3));
    final toolName = toolNames[i % toolNames.length];
    final entryId = nextId();
    final toolCallId = 'tc_${i + 1}';

    // Assistant message with tool call
    entries.add(MessageEntry(
      id: nextId(),
      parentId: entryId,
      timestamp: turnStart.add(const Duration(milliseconds: 100)),
      message: AssistantMessage(content: [
        TextBlock('Analyzing step ${i + 1}...'),
        ToolCallBlock(
          id: toolCallId,
          name: toolName,
          arguments: {'path': 'lib/src/file_${i % 5}.dart'},
        ),
      ]),
    ).toJson());

    // Tool invocation entry
    entries.add(ToolInvocationEntry(
      id: nextId(),
      parentId: entryId,
      timestamp: turnStart.add(const Duration(milliseconds: 200)),
      record: ToolInvocationRecord(
        id: 'ti_${i + 1}',
        parentId: entryId,
        timestamp: turnStart.add(const Duration(milliseconds: 200)),
        toolCallId: toolCallId,
        toolName: toolName,
        isError: false,
        durationMs: 50 + (i % 3) * 25,
      ),
      arguments: {'path': 'lib/src/file_${i % 5}.dart'},
    ).toJson());

    // Tool result message
    entries.add(MessageEntry(
      id: nextId(),
      parentId: entryId,
      timestamp: turnStart.add(const Duration(milliseconds: 500)),
      message: ToolResultMessage(
        toolCallId: toolCallId,
        toolName: toolName,
        content: 'Result from $toolName on file_${i % 5}.dart: OK',
      ),
    ).toJson());

    // Usage entry
    entries.add(UsageEntry(
      id: nextId(),
      parentId: entryId,
      timestamp: turnStart.add(const Duration(milliseconds: 600)),
      record: UsageLedgerEntry(
        id: 'ul_${i + 1}',
        parentId: entryId,
        timestamp: turnStart.add(const Duration(milliseconds: 600)),
        callId: 'c_${i + 1}',
        turnNumber: i + 1,
        inputTokens: 200 + (i * 10),
        outputTokens: 100 + (i * 5),
        cacheReadTokens: i % 5 == 0 ? 50 : 0,
        cacheWriteTokens: 0,
      ),
      model: Model(
        provider: 'openai',
        modelId: 'gpt-4',
        contextWindow: 8192,
      ),
    ).toJson());
  }

  // Final assistant message
  final finalId = nextId();
  entries.add(MessageEntry(
    id: finalId,
    parentId: entries.isNotEmpty ? entries[entries.length - 2]['id'] as String? : null,
    timestamp: fixedBase.add(const Duration(seconds: 160)),
    message: AssistantMessage.text(
      'Security analysis complete. Found 3 medium-severity issues.',
    ),
  ).toJson());

  // Write to JSONL
  final file = File('test/fixtures/mission_50.jsonl');
  final sink = file.openWrite();
  for (final entry in entries) {
    sink.writeln(jsonEncode(entry));
  }
  sink.close();

  print('Generated ${entries.length} entries to test/fixtures/mission_50.jsonl');
}
