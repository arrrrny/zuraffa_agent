// Hand-stepped acceptance subject (spec 112, AC-1): install a sink,
// emit through two subsystem loggers, return the delivered records.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';

List<LogRecord> subject_a1() {
  ZuraffaLogging.reset();
  final sink = MemoryLogSink();
  ZuraffaLogging.install(level: Level.ALL, onRecord: sink.add);
  AgentLog.llm.info('llm lifecycle record');
  AgentLog.engine.warning('engine resilience record');
  ZuraffaLogging.reset();
  return sink.records;
}
