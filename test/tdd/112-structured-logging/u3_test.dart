// GENERATED TEST — `zfa tdd gen U3` (spec 044-test-tdd-generation).
//
// behavior_id: U3
// source_criterion: FR-003, AgentLog.install
// kind: unit
// description: `ZuraffaLogging.install({level, onRecord})` MUST be the only
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `../../../lib/tdd/112-structured-logging/u3_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/u3_subject.dart';

void main() {
  group('U3 (FR-003, AgentLog.install)', () {
    test('U3 — `ZuraffaLogging.install({level, onRecord})` MUST be the only', () {
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final sink = MemoryLogSink();
      // Assertion-shaped guard: a stub subject fails HERE (assertion),
      // keeping the red honest under spec 046's classification grammar.
      expect(() => subject_u3(Level.WARNING, sink.add), returnsNormally);
      // Below-threshold records are filtered by the installed level.
      AgentLog.llm.info('below-threshold');
      // At-threshold records reach the consumer sink.
      AgentLog.llm.warning('delivered');
      expect(sink.length, 1);
      expect(sink.records.single.message, contains('delivered'));
      expect(sink.records.single.loggerName, 'zuraffa.agent.llm');
      // Re-install REPLACES the sink — never stacks listeners.
      final second = MemoryLogSink();
      subject_u3(Level.ALL, second.add);
      AgentLog.eval.info('after-reinstall');
      expect(second.length, 1);
      expect(sink.length, 1);
    });
  });
}
