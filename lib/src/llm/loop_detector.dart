// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/011-loop-detection-llm/spec.md with this attribution retained.

import 'dart:convert';

import '../types.dart';

/// Tunable parameters for loop detection (spec 011 US3 / FR-005).
class LoopDetectorConfig {
  /// Consecutive identical tool-call signatures that fire a tool-loop.
  final int toolLoopThreshold;

  /// Assistant-turn count at which the first stagnation diagnosis runs.
  final int llmCheckAfterTurns;

  /// Turns between stagnation diagnoses after the first check.
  final int llmCheckInterval;

  /// Minimum isStagnant confidence that fires a stagnation detection.
  final double stagnationThreshold;

  /// How many recent messages the diagnosis prompt carries.
  final int diagnosisWindowMessages;

  const LoopDetectorConfig({
    this.toolLoopThreshold = 5,
    this.llmCheckAfterTurns = 30,
    this.llmCheckInterval = 5,
    this.stagnationThreshold = 0.8,
    this.diagnosisWindowMessages = 20,
  });
}

/// One observation outcome (spec 011 Key Entities): what the detector
/// concluded after seeing a message.
class LoopDetectorResult {
  /// Whether a loop (tool-call or cognitive stagnation) was detected.
  final bool isLoop;

  /// Machine-readable cause: 'tool_call_loop' or 'stagnation'.
  final String reason;

  /// Detection confidence — 1.0 for the deterministic tool-loop path,
  /// the LLM verdict's confidence for the stagnation path.
  final double confidence;

  /// Turn number at observation time (assistant-message count).
  final int turnNumber;

  /// Set when a stagnation diagnosis attempt failed to parse (fail-open:
  /// the failure never itself triggers a detection — spec Assumptions).
  final String? diagnosisError;

  const LoopDetectorResult({
    required this.isLoop,
    required this.reason,
    required this.confidence,
    required this.turnNumber,
    this.diagnosisError,
  });

  /// The no-detection result.
  const LoopDetectorResult.continue_(this.turnNumber)
      : isLoop = false,
        reason = '',
        confidence = 0,
        diagnosisError = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoopDetectorResult &&
          runtimeType == other.runtimeType &&
          isLoop == other.isLoop &&
          reason == other.reason &&
          confidence == other.confidence &&
          turnNumber == other.turnNumber &&
          diagnosisError == other.diagnosisError;

  @override
  int get hashCode =>
      Object.hash(isLoop, reason, confidence, turnNumber, diagnosisError);

  @override
  String toString() => 'LoopDetectorResult(isLoop: $isLoop, reason: '
      '$reason, confidence: $confidence, turn: $turnNumber)';
}

/// The loop-detection contract (spec 011 Key Entities): the engine feeds
/// one message at a time as the conversation progresses (spec 002 wires
/// the engine integration).
abstract interface class LoopDetector {
  Future<LoopDetectorResult> observe(AgentMessage message);
}

/// Canonical signature of a tool call: name + argument map with sorted
/// keys (key-order-insensitive), deliberately excluding the per-call `id`
/// (every engine call gets a fresh id — the loop signal is name+arguments;
/// spec 011 FR-001).
String toolCallSignature(ToolCallBlock call) {
  final normalized = jsonEncode(_sortedMap(call.arguments));
  return '${call.name}($normalized)';
}

Map<String, dynamic> _sortedMap(Map<String, dynamic> input) {
  final keys = input.keys.toList()..sort();
  return {for (final k in keys) k: input[k]};
}
