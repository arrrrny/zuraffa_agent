// Hand-stepped acceptance subject (spec 112, AC-4): the pinned level
// policy table.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';

Map<String, Level> subject_a4() => AgentLog.levelPolicy();
