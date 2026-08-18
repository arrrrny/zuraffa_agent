// Manual smoke test: fork, diverge, resume, print divergent contexts
// and byte-identical post-restart context (quickstart Scenario 2).
//
// Usage: dart run example/session_demo.dart

import 'dart:io';

import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() async {
  final tmpDir = Directory.systemTemp.createTempSync('session_demo_');
  final jsonlPath = '${tmpDir.path}/demo.jsonl';

  try {
    // --- Phase 1: Build a session and fork it ---
    final store = JsonlSessionStorage(jsonlPath);
    final session = AgentSession(store);
    await store.init();

    // Append 3 messages on the main branch.
    await session.appendMessage(UserMessage.text('Hello'));
    final m2 = await session
        .appendMessage(UserMessage.text('How are you?'));
    await session.appendMessage(UserMessage.text('Goodbye'));

    // Fork at the second message.
    final forkLeaf = await session.fork(m2, summary: 'explore alternative');

    // Append 2 divergent messages on the forked branch.
    await session.appendMessage(UserMessage.text('Fork: different path'));
    await session.appendMessage(UserMessage.text('Fork: deeper exploration'));

    // --- Phase 2: Resume the original branch ---
    await session.switchTo(m2);
    final originalCtx = await session.buildContext();
    print('=== Original branch context ===');
    for (final msg in originalCtx.messages) {
      final text = switch (msg) {
        UserMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        AssistantMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        ToolResultMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        CustomMessage(:final display) => display,
      };
      print('  [${msg.runtimeType}] $text');
    }

    // --- Phase 3: Switch to the forked branch ---
    await session.switchTo(forkLeaf);
    final forkCtx = await session.buildContext();
    print('\n=== Forked branch context ===');
    for (final msg in forkCtx.messages) {
      final text = switch (msg) {
        UserMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        AssistantMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        ToolResultMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        CustomMessage(:final display) => display,
      };
      print('  [${msg.runtimeType}] $text');
    }

    // --- Phase 4: Restart identity — close/reopen, verify context ---
    final leafBefore = await store.getLeafId();
    await store.close();

    final store2 = JsonlSessionStorage(jsonlPath);
    final session2 = AgentSession(store2);
    await store2.init();
    final restartCtx = await session2.buildContext();
    final leafAfter = await store2.getLeafId();

    print('\n=== Post-restart context (leaf: $leafAfter) ===');
    for (final msg in restartCtx.messages) {
      final text = switch (msg) {
        UserMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        AssistantMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        ToolResultMessage(:final content) =>
          content.whereType<TextBlock>().map((b) => b.text).join(),
        CustomMessage(:final display) => display,
      };
      print('  [${msg.runtimeType}] $text');
    }

    // Byte-identical check.
    final postRestartJson = restartCtx.messages
        .map((m) => m.toString())
        .join('\n');

    // The restart resumes the forked branch (last active), so the contexts
    // should match the fork branch, not the original.
    print('\n=== Validation ===');
    print('Leaf persisted: $leafBefore -> $leafAfter');
    print('Post-restart matches fork branch: '
        '${postRestartJson == forkCtx.messages.map((m) => m.toString()).join('\n')}');
    await store2.close();
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
