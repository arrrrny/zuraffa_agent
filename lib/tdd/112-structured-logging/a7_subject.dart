// Hand-stepped acceptance subject (spec 112, AC-7): the documentation
// self-check over the shipped ARCHITECTURE.md sections (the test reads
// the file; lib stays dart:io-free).
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/logging/agent_log.dart';

void subject_a7(String hierarchy, String policy, String sinkRecipe) =>
    AgentLog.document(
      hierarchy: hierarchy,
      policy: policy,
      sinkRecipe: sinkRecipe,
    );
