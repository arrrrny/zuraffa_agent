// Hand-stepped acceptance subject (spec 112, AC-3): install at WARNING;
// FINE and INFO are filtered, WARNING and SEVERE are delivered.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';

List<LogRecord> subject_a3() {
  ZuraffaLogging.reset();
  final sink = MemoryLogSink();
  ZuraffaLogging.install(level: Level.WARNING, onRecord: sink.add);
  AgentLog.llm.log(AgentLog.transportLevel, 'a fine record');
  AgentLog.llm.log(AgentLog.lifecycleLevel, 'an info record');
  AgentLog.mcp.log(AgentLog.resilienceLevel, 'a warning record');
  AgentLog.mcp.log(AgentLog.terminalLevel, 'a severe record');
  ZuraffaLogging.reset();
  return sink.records;
}
