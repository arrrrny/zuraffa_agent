// GENERATED TEST — `zfa tdd gen U4` (spec 044-test-tdd-generation).
//
// behavior_id: U4
// source_criterion: FR-004, AgentLog.logger
// kind: unit
// description: Emission MUST be safe and cheap before install: no listener
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/112-structured-logging/u4_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/u4_subject.dart';

void main() {
  group('U4 (FR-004, AgentLog.logger)', () {
    test('U4 — Emission MUST be safe and cheap before install: no listener', () {
      // No sink installed: emission must be silent, never throw.
      ZuraffaLogging.reset();
      addTearDown(ZuraffaLogging.reset);
      final logger = subject_u4('session');
      expect(() {
        logger.fine('transport bytes pre-install');
        logger.info('lifecycle pre-install');
        logger.warning('resilience pre-install');
        logger.severe('terminal pre-install');
      }, returnsNormally);
      // The pinned subsystem set resolves off-hierarchy refusal too.
      expect(() => subject_u4('unknown'), throwsArgumentError);
      // Once a sink IS installed, the skipped-level records stay absent
      // while at-threshold records arrive (the cheap-path contract).
      final sink = MemoryLogSink();
      ZuraffaLogging.install(level: Level.SEVERE, onRecord: sink.add);
      logger.info('filtered');
      logger.severe('delivered');
      expect(sink.length, 1);
      expect(sink.records.single.message, 'delivered');
    });
  });
}
