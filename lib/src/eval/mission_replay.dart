// Mission replay harness (issue #115).
//
// Composes the engine stack the eval tests already exercise —
// CassetteReplayLlmClient, EngineLoopExecutor, MissionRunner — so a golden
// mission can actually be replayed from its committed cassette and graded,
// instead of the gate simulating passes with hardcoded counts. The CLI gate
// (tool/run_eval_suites.dart) and SuiteRunner share this wiring.
//
// Pure Dart (FR-005): no dart:io — the cassette arrives as already-decoded
// JSON; the CLI owns the file I/O boundary.

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/eval/cassette_replay_llm_client.dart';
import 'package:zuraffa_agent/src/eval/suite_loader.dart'
    show SuiteLoadException;

/// A cassette parsed for replay: the golden mission plus the recorded
/// completion sequence.
class MissionReplay {
  /// The golden mission the cassette records.
  final GoldenMission mission;

  /// The recorded completions, consumed in order by the replay client.
  final List<Map<String, dynamic>> completions;

  /// Builds a replay from an already-parsed mission and completion list.
  const MissionReplay({required this.mission, required this.completions});

  /// Parses a decoded cassette document (the JSON of `eval/cassettes/<id>.json`).
  ///
  /// Throws [SuiteLoadException] on a malformed cassette — a corrupt corpus
  /// file fails the gate loudly, never shrinks it silently.
  factory MissionReplay.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const SuiteLoadException('cassette is missing a string "id"');
    }
    final cassette = json['cassette'];
    if (cassette is! Map) {
      throw SuiteLoadException('cassette "$id" has no cassette object');
    }
    final rawCompletions = cassette['completions'];
    if (rawCompletions is! List || rawCompletions.isEmpty) {
      throw SuiteLoadException('cassette "$id" carries no completions');
    }
    final completions = <Map<String, dynamic>>[];
    for (final entry in rawCompletions) {
      if (entry is Map<String, dynamic>) {
        completions.add(entry);
      } else if (entry is Map) {
        completions.add(Map<String, dynamic>.from(entry));
      } else {
        throw SuiteLoadException(
          'cassette "$id" has a non-object completion entry',
        );
      }
    }
    final bindings = json['graderBindings'];
    final mission = GoldenMission(
      id: id,
      name: json['name'] is String ? json['name'] as String : id,
      cassette: Map<String, dynamic>.from(cassette),
      taskDefinition: json['taskDefinition'] is String
          ? json['taskDefinition'] as String
          : '',
      graderBindings: switch (bindings) {
        final List<dynamic> l => [for (final b in l) '$b'],
        _ => <String>[],
      },
    );
    return MissionReplay(
      mission: mission,
      completions: List<Map<String, dynamic>>.unmodifiable(completions),
    );
  }
}

/// Tool dispatcher used under replay: every planned call succeeds with a
/// deterministic canned result. The cassettes pin completions and event
/// shapes, not tool payloads, so the dispatcher echoes a fixed success and
/// the recorded completions drive the loop shape.
class ReplayToolDispatcher implements ToolDispatcher {
  /// Creates the canned-success dispatcher.
  ReplayToolDispatcher();

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    return ToolDispatchResult(
      success: true,
      result: 'replayed tool result',
      error: '',
      artifactRefs: [],
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    return List<ToolDispatchResult>.generate(
      calls.length,
      (_) => ToolDispatchResult(
        success: true,
        result: 'replayed tool result',
        error: '',
        artifactRefs: [],
      ),
    );
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) {
    return true;
  }
}

/// Plans one generic dispatch per `tool_calls` completion — the shape every
/// committed cassette was recorded with (one ToolCallStarted/Completed pair
/// per tool_calls turn).
/// Paces the replay loop: one recording per turn.
///
/// A `tool_calls` completion plans one generic dispatch (the recorded
/// shape: one ToolCallStarted/Completed pair per tool_calls turn). A
/// `stop` completion would otherwise end the mission while the cassette
/// still has recordings to serve, so until the last recording the planner
/// plans one no-op continuation dispatch — which keeps the loop going
/// without steering. The final recording stops the mission naturally, so
/// its content comes back as the summary exactly as recorded.
class ReplayToolPlanner implements ToolCallPlanner {
  /// Creates the pacing planner for a cassette with [turnsToServe]
  /// recorded completions.
  const ReplayToolPlanner({required this.turnsToServe});

  /// How many completions the cassette carries; the mission must not stop
  /// naturally before all of them have been served.
  final int turnsToServe;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    if (completion.finishReason == 'tool_calls') {
      return const [
        ToolCall(
          toolName: 'replay.tool',
          arguments: {},
          executionMode: 'sequential',
        ),
      ];
    }
    // Assistant messages == recordings served so far (one per turn).
    final served = transcript.where((m) => m.role == 'assistant').length;
    if (served < turnsToServe) {
      return const [
        ToolCall(
          toolName: 'replay.continue',
          arguments: {},
          executionMode: 'sequential',
        ),
      ];
    }
    return const <ToolCall>[];
  }
}

/// The outcome of one replayed mission run.
class ReplayRunResult {
  /// The replayed mission's id.
  final String missionId;

  /// The mission's summary — the final assistant content on natural stop.
  final String? summary;

  /// True when the mission finished `completed` (natural stop within budget).
  final bool completed;

  /// Builds a run outcome.
  const ReplayRunResult({
    required this.missionId,
    required this.summary,
    required this.completed,
  });
}

/// Replays golden missions from their cassettes through the real engine loop.
class MissionReplayRunner {
  /// Cassettes are 2–3 completions deep; 16 turns and a matching repetition
  /// threshold leave ample margin without letting a malformed cassette spin.
  static const int _maxTurns = 16;

  /// Runs one replay: the cassette's recorded completions are served to the
  /// engine by [CassetteReplayLlmClient], planned tool calls dispatch
  /// successfully, and the mission's final summary comes back for grading.
  ///
  /// Throws [StateError] when the cassette is exhausted mid-mission (the
  /// replay client never falls through to a live provider).
  static Future<ReplayRunResult> run(MissionReplay replay) async {
    final client = CassetteReplayLlmClient(completions: replay.completions);
    final loop = EngineLoop(
      id: 'eval-replay-${replay.mission.id}',
      sessionId: 'eval-replay',
      maxTurns: _maxTurns,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: _maxTurns,
    );
    const policy = StopPolicy(
      id: 'eval-replay',
      maxTurns: _maxTurns,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: _maxTurns,
    );
    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, client),
      toolDispatcher: ReplayToolDispatcher(),
      stopPolicy: policy,
      onEvent: (_) {},
    );
    final result = await runner.run(
      missionId: replay.mission.id,
      messages: const [ChatMessage(role: 'user', content: 'run the mission')],
      planner: ReplayToolPlanner(turnsToServe: replay.completions.length),
    );
    return ReplayRunResult(
      missionId: replay.mission.id,
      summary: result.summary,
      completed: result.status == MissionStatus.completed,
    );
  }
}
