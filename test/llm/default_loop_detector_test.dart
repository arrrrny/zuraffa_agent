// Tests for lib/src/llm/default_loop_detector.dart — Spec 011 runtime paths.
// Behaviors U4-U11 + acceptance A1-A6 — see specs/011-loop-detection-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/default_loop_detector.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/loop_detector.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'fake_llm_client.dart';

ToolCallBlock call(String name, Map<String, dynamic> args, [String id = 'c']) =>
    ToolCallBlock(id: id, name: name, arguments: args);

AssistantMessage toolTurn(ToolCallBlock toolCall) =>
    AssistantMessage(content: [toolCall]);

/// A diagnosis verdict scripted as LLM response content.
ScriptedOutcome verdict(
  String content, {
  String? name,
}) =>
    ScriptedOutcome(response: LlmResponse(content: content));

void main() {
  group('DefaultLoopDetector — tool-loop path (U4-U6, A1-A3)', () {
    test('U4: the streak fires exactly at toolLoopThreshold consecutive identical calls — not before', () async {
      final detector = DefaultLoopDetector(
        config: const LoopDetectorConfig(), // threshold 5
      );
      for (var i = 1; i <= 4; i++) {
        final r = await detector.observe(
            toolTurn(call('read_file', {'path': 'lib/a.dart'})));
        expect(r.isLoop, isFalse, reason: 'call #$i must not fire');
      }
      final fifth = await detector
          .observe(toolTurn(call('read_file', {'path': 'lib/a.dart'})));
      expect(fifth.isLoop, isTrue);
      expect(fifth.reason, 'tool_call_loop');
      expect(fifth.confidence, 1.0);
      expect(fifth.turnNumber, 5);
    });

    test('U5: a different tool-call signature resets the streak', () async {
      final detector = DefaultLoopDetector();
      for (var i = 0; i < 4; i++) {
        await detector.observe(toolTurn(call('read_file', {'path': 'lib/a.dart'})));
      }
      // A different call breaks the streak.
      var r = await detector.observe(toolTurn(call('read_file', {'path': 'lib/b.dart'})));
      expect(r.isLoop, isFalse);
      // 4 more of the original call — still no loop (streak restarted).
      for (var i = 0; i < 4; i++) {
        r = await detector.observe(toolTurn(call('read_file', {'path': 'lib/a.dart'})));
        expect(r.isLoop, isFalse);
      }
      // The 5th consecutive identical call fires.
      r = await detector.observe(toolTurn(call('read_file', {'path': 'lib/a.dart'})));
      expect(r.isLoop, isTrue);
    });

    test('U6: tool-result and user messages between identical calls do not reset the streak', () async {
      final detector = DefaultLoopDetector();
      for (var i = 0; i < 4; i++) {
        await detector.observe(toolTurn(call('read_file', {'path': 'x.dart'})));
        await detector.observe(ToolResultMessage(
          toolCallId: 'c',
          toolName: 'read_file',
          content: 'content-$i',
        ));
        await detector.observe(UserMessage.text('proceed'));
      }
      final r = await detector.observe(toolTurn(call('read_file', {'path': 'x.dart'})));
      expect(r.isLoop, isTrue, reason: '5th identical call with non-assistant interleaves must fire');
    });

    test('A1: 5 identical read_file("lib/a.dart") calls in a row are detected as a loop (SC-001)', () async {
      final detector = DefaultLoopDetector();
      LoopDetectorResult? detection;
      for (var i = 0; i < 5; i++) {
        final r = await detector
            .observe(toolTurn(call('read_file', {'path': 'lib/a.dart'})));
        if (r.isLoop) detection = r;
      }
      expect(detection, isNotNull);
      expect(detection!.reason, 'tool_call_loop');
      expect(detection.confidence, 1.0);
    });

    test('A2: 50 varied tool calls never fire a tool-loop detection (SC-003)', () async {
      final detector = DefaultLoopDetector();
      var detections = 0;
      for (var i = 0; i < 50; i++) {
        final r = await detector.observe(toolTurn(call(
          'read_file',
          {'path': 'lib/file-$i.dart'},
        )));
        if (r.isLoop) detections++;
      }
      expect(detections, 0);
    });

    test('A3: a call→result→call→result chain of identical calls accumulates and fires (AC-3)', () async {
      final detector = DefaultLoopDetector();
      LoopDetectorResult? last;
      for (var i = 0; i < 5; i++) {
        last = await detector.observe(toolTurn(call('grep', {'q': 'TODO'})));
        await detector.observe(ToolResultMessage(
            toolCallId: 'c', toolName: 'grep', content: 'no matches'));
      }
      expect(last!.isLoop, isTrue);
    });
  });

  group('DefaultLoopDetector — stagnation path (U7-U11, A4-A6)', () {
    test('U7: without an LlmClient the pure heuristic path runs — no diagnosis calls, tool-loop still works', () async {
      final detector = DefaultLoopDetector(); // no client
      for (var i = 0; i < 60; i++) {
        await detector.observe(AssistantMessage.text('progress-$i'));
      }
      expect(detector.diagnosisCalls, 0);
      // Tool-loop detection unaffected.
      for (var i = 0; i < 5; i++) {
        final r = await detector.observe(toolTurn(call('read_file', {'p': 'a'})));
        if (i < 4) expect(r.isLoop, isFalse);
        if (i == 4) expect(r.isLoop, isTrue);
      }
    });

    test('U8: first diagnosis fires exactly at llmCheckAfterTurns, then every llmCheckInterval turns', () async {
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: List.generate(
          20,
          (i) => verdict('{"isStagnant": false, "confidence": 0.1, "reason": "healthy"}'),
        ),
      );
      final detector = DefaultLoopDetector(
        client: client,
        config: const LoopDetectorConfig(
          llmCheckAfterTurns: 6,
          llmCheckInterval: 2,
        ),
      );
      for (var turn = 1; turn <= 10; turn++) {
        await detector.observe(AssistantMessage.text('t$turn'));
        if (turn < 6) {
          expect(detector.diagnosisCalls, 0, reason: 'no diagnosis before turn 6');
        } else if (turn == 6) {
          expect(detector.diagnosisCalls, 1, reason: 'first diagnosis at turn 6');
        } else if (turn == 7) {
          expect(detector.diagnosisCalls, 1, reason: 'interval 2: no check at turn 7');
        } else if (turn == 8) {
          expect(detector.diagnosisCalls, 2, reason: 'second diagnosis at turn 8');
        } else if (turn == 10) {
          expect(detector.diagnosisCalls, 3, reason: 'third diagnosis at turn 10');
        }
      }
    });

    test('U9: an isStagnant verdict with confidence >= threshold produces a detection carrying the verdict', () async {
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: [
          verdict('{"isStagnant": true, "confidence": 0.92, "reason": "repeated identical reasoning"}'),
        ],
      );
      final detector = DefaultLoopDetector(
        client: client,
        config: const LoopDetectorConfig(llmCheckAfterTurns: 3),
      );
      for (var i = 1; i <= 2; i++) {
        final r = await detector.observe(AssistantMessage.text('stuck-$i'));
        expect(r.isLoop, isFalse);
      }
      final r = await detector.observe(AssistantMessage.text('stuck-3'));
      expect(r.isLoop, isTrue);
      expect(r.reason, 'stagnation');
      expect(r.confidence, 0.92);
      expect(client.requests, hasLength(1));
      // The diagnosis prompt carries the recent window.
      expect(client.requests.single.messages, isNotEmpty);
    });

    test('U10: a verdict with confidence below the threshold produces no detection (boundary at exactly the threshold fires)', () async {
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: [
          verdict('{"isStagnant": true, "confidence": 0.79, "reason": "mild"}'),
          verdict('{"isStagnant": true, "confidence": 0.8, "reason": "boundary"}'),
        ],
      );
      final detector = DefaultLoopDetector(
        client: client,
        config: const LoopDetectorConfig(
          llmCheckAfterTurns: 3,
          llmCheckInterval: 1,
          stagnationThreshold: 0.8,
        ),
      );
      for (var i = 1; i <= 3; i++) {
        final r = await detector.observe(AssistantMessage.text('t$i'));
        expect(r.isLoop, isFalse, reason: '0.79 < 0.8 must not fire');
      }
      // Turn 4 → second diagnosis at exactly the threshold → fires.
      final r = await detector.observe(AssistantMessage.text('t4'));
      expect(r.isLoop, isTrue);
      expect(r.confidence, 0.8);
    });

    test('U11: a malformed diagnosis response is fail-open — no detection, error surfaced', () async {
      // Shape 1: not JSON at all.
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: [verdict('the agent is definitely stuck, trust me')],
      );
      final detector = DefaultLoopDetector(
        client: client,
        config: const LoopDetectorConfig(llmCheckAfterTurns: 3),
      );
      for (var i = 1; i <= 3; i++) {
        final r = await detector.observe(AssistantMessage.text('t$i'));
        expect(r.isLoop, isFalse, reason: 'malformed verdict must never fire');
        if (i == 3) {
          expect(r.diagnosisError, isNotNull);
        }
      }

      // Shape 2: valid JSON but not an object (e.g. a bare array).
      final client2 = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: [verdict('["looks", "like", "stuck"]')],
      );
      final detector2 = DefaultLoopDetector(
        client: client2,
        config: const LoopDetectorConfig(llmCheckAfterTurns: 3),
      );
      for (var i = 1; i <= 3; i++) {
        final r = await detector2.observe(AssistantMessage.text('t$i'));
        expect(r.isLoop, isFalse, reason: 'non-object verdict must never fire');
        if (i == 3) {
          expect(r.diagnosisError, isNotNull);
        }
      }

      // Shape 3: object with wrong-typed fields.
      final client3 = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: [verdict('{"isStagnant": "yes", "confidence": 1}')],
      );
      final detector3 = DefaultLoopDetector(
        client: client3,
        config: const LoopDetectorConfig(llmCheckAfterTurns: 3),
      );
      for (var i = 1; i <= 3; i++) {
        final r = await detector3.observe(AssistantMessage.text('t$i'));
        expect(r.isLoop, isFalse, reason: 'wrong-typed verdict must never fire');
        if (i == 3) {
          expect(r.diagnosisError, isNotNull);
        }
      }
    });

    test('A4: with llmCheckAfterTurns=30 the first diagnosis fires exactly at turn 30 (AC-4)', () async {
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: List.generate(
          5,
          (i) => verdict('{"isStagnant": false, "confidence": 0.1, "reason": "ok"}'),
        ),
      );
      final detector = DefaultLoopDetector(client: client); // defaults: 30
      for (var turn = 1; turn <= 30; turn++) {
        await detector.observe(AssistantMessage.text('turn-$turn'));
        if (turn < 30) {
          expect(detector.diagnosisCalls, 0, reason: 'turn $turn');
        }
      }
      expect(detector.diagnosisCalls, 1);
    });

    test('A5: stagnation confidence 0.9 with threshold 0.8 → stop-signal result (SC-002)', () async {
      // 30+ turns of similar reasoning with no progress.
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: List.generate(
          10,
          (i) => i == 0
              ? verdict('{"isStagnant": true, "confidence": 0.9, "reason": "repeating the same plan without executing"}')
              : verdict('{"isStagnant": false, "confidence": 0.1, "reason": "ok"}'),
        ),
      );
      final detector = DefaultLoopDetector(client: client);
      LoopDetectorResult? stopSignal;
      for (var turn = 1; turn <= 35; turn++) {
        final r = await detector.observe(
            AssistantMessage.text('Let me think about the plan again...'));
        if (r.isLoop) {
          stopSignal = r;
          break;
        }
      }
      expect(stopSignal, isNotNull);
      expect(stopSignal!.reason, 'stagnation');
      expect(stopSignal.confidence, 0.9);
      expect(stopSignal.turnNumber, 30);
    });

    test('A6: a 60-turn non-stagnant mission yields zero detections (SC-003)', () async {
      final client = FakeLlmClient(
        providerName: 'diagnosis',
        outcomes: List.generate(
          10,
          (i) => verdict('{"isStagnant": false, "confidence": 0.05, "reason": "steady progress"}'),
        ),
      );
      final detector = DefaultLoopDetector(client: client);
      var detections = 0;
      for (var turn = 1; turn <= 60; turn++) {
        final r = await detector.observe(
            AssistantMessage.text('step $turn: doing a new thing'));
        if (r.isLoop) detections++;
      }
      expect(detections, 0);
      expect(detector.diagnosisCalls, greaterThan(0));
    });
  });
}
