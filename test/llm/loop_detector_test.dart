// Tests for lib/src/llm/loop_detector.dart — Spec 011 value layer.
// Behaviors U1-U3 — see specs/011-loop-detection-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/loop_detector.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  group('LoopDetector value layer (U1-U3)', () {
    test('U1: LoopDetectorConfig defaults — 5/30/5/0.8/20', () {
      const config = LoopDetectorConfig();
      expect(config.toolLoopThreshold, 5);
      expect(config.llmCheckAfterTurns, 30);
      expect(config.llmCheckInterval, 5);
      expect(config.stagnationThreshold, 0.8);
      expect(config.diagnosisWindowMessages, 20);
    });

    test('U2: LoopDetectorResult carries isLoop/reason/confidence/turnNumber with value semantics', () {
      const a = LoopDetectorResult(
        isLoop: true,
        reason: 'tool_call_loop',
        confidence: 1.0,
        turnNumber: 12,
      );
      const b = LoopDetectorResult(
        isLoop: true,
        reason: 'tool_call_loop',
        confidence: 1.0,
        turnNumber: 12,
      );
      const c = LoopDetectorResult(
        isLoop: false,
        reason: '',
        confidence: 0,
        turnNumber: 12,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('tool_call_loop'));
    });

    test('U3: toolCallSignature is key-order-insensitive and call-id-insensitive', () {
      final callA = const ToolCallBlock(
        id: 'call-1',
        name: 'read_file',
        arguments: {'path': 'lib/a.dart', 'offset': 10},
      );
      final callB = const ToolCallBlock(
        id: 'call-999', // different id, same name+args
        name: 'read_file',
        arguments: {'offset': 10, 'path': 'lib/a.dart'}, // reordered keys
      );
      final callC = const ToolCallBlock(
        id: 'call-2',
        name: 'read_file',
        arguments: {'path': 'lib/other.dart', 'offset': 10},
      );
      expect(toolCallSignature(callA), toolCallSignature(callB));
      expect(toolCallSignature(callA), isNot(toolCallSignature(callC)));

      // Null-safe on empty arguments.
      expect(
        toolCallSignature(const ToolCallBlock(id: 'x', name: 'noop', arguments: {})),
        toolCallSignature(const ToolCallBlock(id: 'y', name: 'noop', arguments: {})),
      );
    });
  });
}
