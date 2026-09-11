// Hand-stepped acceptance subject (spec 112, AC-2): with NO sink
// installed, emission at every level is silent and never throws.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/logging/agent_log.dart';

Map<String, Object?> subject_a2() {
  ZuraffaLogging.reset();
  var emitted = 0;
  for (final subsystem in AgentLog.subsystems) {
    final logger = AgentLog.logger(subsystem);
    logger.log(AgentLog.transportLevel, 'fine pre-install');
    logger.log(AgentLog.lifecycleLevel, 'info pre-install');
    logger.log(AgentLog.resilienceLevel, 'warning pre-install');
    logger.log(AgentLog.terminalLevel, 'severe pre-install');
    emitted += 4;
  }
  return {'status': 'silent-ok', 'emitted': emitted};
}
