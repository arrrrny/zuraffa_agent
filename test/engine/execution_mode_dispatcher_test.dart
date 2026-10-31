// Issue arrrrny/zuraffa_agent#4 (R3) — spec-003 A3 behavioral coverage.
//
// The audit (specs/003-tools-and-mcp/tdd/verification.md, finding F4): "A3
// (parallel batch runs concurrently, results collected in call order) is
// marked DONE but the cited test verifies only the ToolDispatchMode
// entity/codegen. No behavioral parallel-batch test exists." Every shipped
// dispatchBatch implementation runs strictly one-at-a-time (Allowlist and
// Memory are `for ... await` loops; the gate and oversized decorators
// delegate). ExecutionModeToolDispatcher is the batch seam that honors each
// ToolCall.executionMode:
//
//   - 'parallel' calls in a contiguous run dispatch CONCURRENTLY;
//   - 'sequential' calls dispatch one at a time, in call order;
//   - results are reassembled POSITIONALLY — results[i] is always the
//     outcome of calls[i], regardless of completion order (issue #4 R3.1
//     "sequential/parallel execution modes");
//   - dispatch / validateSchema / checkRiskTier delegate untouched, so the
//     decorator composes with the approval gate and oversized-policy chain.
//
// Concurrency is asserted by overlapping dispatch intervals recorded by the
// inner dispatcher — deterministic, no wall-clock margins.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/execution_mode_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

class _Interval {
  _Interval(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool overlaps(_Interval other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

class _RecordingDispatcher implements ToolDispatcher {
  final List<_Interval> intervals = [];
  final List<String> order = [];

  ToolDispatchResult _result(String toolName) => ToolDispatchResult(
    success: true,
    result: 'ran:$toolName',
    error: '',
    artifactRefs: const [],
  );

  Future<ToolDispatchResult> _run(
    String toolName,
    int ms,
    Map<String, dynamic> arguments,
  ) async {
    final start = DateTime.now();
    order.add('start:$toolName');
    await Future<void>.delayed(Duration(milliseconds: ms));
    order.add('end:$toolName');
    intervals.add(_Interval(start, DateTime.now()));
    return _result(toolName);
  }

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async => _run(toolName, (arguments['ms'] as num).toInt(), arguments);

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => [
    for (final call in calls)
      await _run(
        call.toolName,
        (call.arguments['ms'] as num).toInt(),
        call.arguments,
      ),
  ];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const ['schema-error-from-inner'];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => riskTier == 'safe' || isInternalMission;
}

ToolCall _call(String name, int ms, String mode) =>
    ToolCall(toolName: name, arguments: {'ms': ms}, executionMode: mode);

void main() {
  group('ExecutionModeToolDispatcher — parallel runs concurrently (A3)', () {
    test('parallel calls overlap and results stay in call order', () async {
      final inner = _RecordingDispatcher();
      final dispatcher = ExecutionModeToolDispatcher(inner: inner);

      // The FIRST call is the slow one: a sequential executor would finish
      // it before even starting the second, so no overlap is possible.
      final results = await dispatcher.dispatchBatch(
        calls: [
          _call('slow.fetch', 120, 'parallel'),
          _call('fast.fetch', 20, 'parallel'),
        ],
        isInternalMission: false,
      );

      expect(inner.intervals, hasLength(2));
      expect(
        inner.intervals[0].overlaps(inner.intervals[1]),
        isTrue,
        reason: 'parallel calls must run concurrently',
      );
      // Positional results, NOT completion order (fast finished first).
      expect(results[0].result, 'ran:slow.fetch');
      expect(results[1].result, 'ran:fast.fetch');
    });

    test('a larger parallel wave runs concurrently', () async {
      final inner = _RecordingDispatcher();
      final dispatcher = ExecutionModeToolDispatcher(inner: inner);

      final results = await dispatcher.dispatchBatch(
        calls: [
          _call('a', 60, 'parallel'),
          _call('b', 60, 'parallel'),
          _call('c', 60, 'parallel'),
          _call('d', 60, 'parallel'),
        ],
        isInternalMission: false,
      );

      expect(results, hasLength(4));
      // Four 60ms tools cannot all pairwise overlap under a sequential
      // runner within one wave: assert the wave's wall clock stays well
      // under the sequential sum (4 x 60ms).
      final start = inner.intervals
          .map((i) => i.start)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final end = inner.intervals
          .map((i) => i.end)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      expect(
        end.difference(start).inMilliseconds,
        lessThan(220),
        reason: 'the wave must overlap, not sum',
      );
    });
  });

  group('ExecutionModeToolDispatcher — sequential stays strictly ordered', () {
    test('sequential calls never overlap and run in call order', () async {
      final inner = _RecordingDispatcher();
      final dispatcher = ExecutionModeToolDispatcher(inner: inner);

      final results = await dispatcher.dispatchBatch(
        calls: [
          _call('first', 40, 'sequential'),
          _call('second', 40, 'sequential'),
        ],
        isInternalMission: false,
      );

      expect(
        inner.intervals[0].overlaps(inner.intervals[1]),
        isFalse,
        reason: 'sequential calls must not overlap',
      );
      expect(results[0].result, 'ran:first');
      expect(results[1].result, 'ran:second');
      expect(inner.order, [
        'start:first',
        'end:first',
        'start:second',
        'end:second',
      ]);
    });
  });

  group('ExecutionModeToolDispatcher — mixed batches', () {
    test(
      'contiguous runs: sequential bookends around a concurrent wave',
      () async {
        final inner = _RecordingDispatcher();
        final dispatcher = ExecutionModeToolDispatcher(inner: inner);

        final results = await dispatcher.dispatchBatch(
          calls: [
            _call('s1', 30, 'sequential'),
            _call('p1', 80, 'parallel'),
            _call('p2', 20, 'parallel'),
            _call('s2', 30, 'sequential'),
          ],
          isInternalMission: false,
        );

        // Positional reassembly across mode boundaries.
        expect(results.map((r) => r.result).toList(), [
          'ran:s1',
          'ran:p1',
          'ran:p2',
          'ran:s2',
        ]);
        // The parallel pair overlapped…
        expect(inner.intervals[1].overlaps(inner.intervals[2]), isTrue);
        // …and the sequential bookends never overlap the wave: s1 finished
        // before the wave started, s2 started after the whole wave ended.
        expect(
          inner.intervals[0].end.isBefore(inner.intervals[1].start),
          isTrue,
        );
        expect(
          inner.intervals[2].end.isBefore(inner.intervals[3].start),
          isTrue,
        );
      },
    );

    test('an empty batch returns an empty list', () async {
      final dispatcher = ExecutionModeToolDispatcher(
        inner: _RecordingDispatcher(),
      );
      expect(
        await dispatcher.dispatchBatch(
          calls: const [],
          isInternalMission: true,
        ),
        isEmpty,
      );
    });
  });

  group('ExecutionModeToolDispatcher — delegation and composition', () {
    test(
      'dispatch, validateSchema and checkRiskTier delegate to the inner',
      () async {
        final inner = _RecordingDispatcher();
        final dispatcher = ExecutionModeToolDispatcher(inner: inner);

        final result = await dispatcher.dispatch(
          toolName: 'solo',
          arguments: {'ms': 1},
          isInternalMission: false,
        );
        expect(result.result, 'ran:solo');
        expect(
          dispatcher.validateSchema(schema: const {}, arguments: const {}),
          ['schema-error-from-inner'],
        );
        expect(
          dispatcher.checkRiskTier(riskTier: 'admin', isInternalMission: false),
          isFalse,
        );
      },
    );
  });
}
