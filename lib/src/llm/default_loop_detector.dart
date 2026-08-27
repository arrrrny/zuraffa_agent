// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/011-loop-detection-llm/spec.md with this attribution retained.

import 'dart:convert';

import '../types.dart';
import 'llm_client.dart';
import 'loop_detector.dart';

/// The default [LoopDetector]: deterministic tool-call streak detection
/// plus optional LLM-based cognitive-stagnation diagnosis (spec 011
/// US1/US2).
///
/// Streak semantics (spec AC-2/AC-3): a *different* tool-call signature
/// resets the streak; tool-result and user messages do not. Turn counting:
/// one assistant message = one turn; the first stagnation diagnosis runs at
/// [LoopDetectorConfig.llmCheckAfterTurns] and then every
/// [LoopDetectorConfig.llmCheckInterval] turns.
class DefaultLoopDetector implements LoopDetector {
  final LoopDetectorConfig config;
  final LlmClient? client;

  /// Sliding window of the conversation fed to the detector (bounded by
  /// [LoopDetectorConfig.diagnosisWindowMessages]).
  final List<AgentMessage> _window = [];

  String? _lastSignature;
  int _streak = 0;
  int _turns = 0;
  int _lastDiagnosisTurn = 0;
  bool _detected = false;

  /// Number of stagnation diagnoses issued (observable for tests/ops).
  int diagnosisCalls = 0;

  DefaultLoopDetector({this.config = const LoopDetectorConfig(), this.client});

  @override
  Future<LoopDetectorResult> observe(AgentMessage message) async {
    _window.add(message);
    if (_window.length > config.diagnosisWindowMessages) {
      _window.removeRange(0, _window.length - config.diagnosisWindowMessages);
    }

    // A prior detection latches: every subsequent observation keeps
    // reporting it (the engine stops the mission on the first signal).
    if (_detected) {
      return LoopDetectorResult(
        isLoop: true,
        reason: _latchedReason,
        confidence: _latchedConfidence,
        turnNumber: _turns,
      );
    }

    if (message is AssistantMessage) {
      _turns++;
      final toolCalls = message.content.whereType<ToolCallBlock>();
      for (final toolCall in toolCalls) {
        final signature = toolCallSignature(toolCall);
        if (signature == _lastSignature) {
          _streak++;
        } else {
          _lastSignature = signature;
          _streak = 1;
        }
        if (_streak >= config.toolLoopThreshold) {
          _detected = true;
          _latchedReason = 'tool_call_loop';
          _latchedConfidence = 1.0;
          return LoopDetectorResult(
            isLoop: true,
            reason: 'tool_call_loop',
            confidence: 1.0,
            turnNumber: _turns,
          );
        }
      }
    }

    // Stagnation diagnosis (spec US2): client-optional — without one, the
    // heuristic path simply never triggers a diagnosis. The FIRST check
    // fires at exactly llmCheckAfterTurns (regardless of interval); later
    // checks fire every llmCheckInterval turns after the last one.
    if (client != null &&
        _turns >= config.llmCheckAfterTurns &&
        (_lastDiagnosisTurn == 0 ||
            _turns - _lastDiagnosisTurn >= config.llmCheckInterval)) {
      _lastDiagnosisTurn = _turns;
      diagnosisCalls++;
      final verdict = await _diagnose();
      if (verdict.isStagnant && verdict.confidence >= config.stagnationThreshold) {
        _detected = true;
        _latchedReason = 'stagnation';
        _latchedConfidence = verdict.confidence;
        return LoopDetectorResult(
          isLoop: true,
          reason: 'stagnation',
          confidence: verdict.confidence,
          turnNumber: _turns,
        );
      }
      return LoopDetectorResult(
        isLoop: false,
        reason: '',
        confidence: 0,
        turnNumber: _turns,
        diagnosisError: verdict.error,
      );
    }

    return LoopDetectorResult.continue_(_turns);
  }

  late String _latchedReason;
  late double _latchedConfidence;

  Future<_StagnationVerdict> _diagnose() async {
    try {
      final response = await client!.generate(LlmRequest(
        systemPrompt: 'You are a mission-progress monitor. Judge whether the '
            'agent is stuck in cognitive stagnation (repeating reasoning or '
            'actions without making progress). Answer ONLY with a JSON '
            'object: {"isStagnant": bool, "confidence": number between 0 and '
            '1, "reason": string}.',
        messages: List.unmodifiable(_window),
      ));
      final decoded = jsonDecode(response.content);
      if (decoded is! Map) {
        return _StagnationVerdict.error(
            'diagnosis response is not a JSON object');
      }
      final isStagnant = decoded['isStagnant'];
      final confidence = decoded['confidence'];
      if (isStagnant is! bool || confidence is! num) {
        return _StagnationVerdict.error(
            'diagnosis verdict missing isStagnant(bool)/confidence(number)');
      }
      return _StagnationVerdict(
        isStagnant: isStagnant,
        confidence: confidence.toDouble(),
        reason: decoded['reason'] is String ? decoded['reason'] as String : '',
      );
    } on FormatException catch (e) {
      return _StagnationVerdict.error('diagnosis response not valid JSON: $e');
    } catch (e) {
      return _StagnationVerdict.error('diagnosis call failed: $e');
    }
  }
}

class _StagnationVerdict {
  final bool isStagnant;
  final double confidence;
  final String reason;
  final String? error;

  const _StagnationVerdict({
    required this.isStagnant,
    required this.confidence,
    required this.reason,
    this.error,
  });

  const _StagnationVerdict.error(String message)
      : isStagnant = false,
        confidence = 0,
        reason = '',
        error = message;
}
