// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#29 (uri_does_not_exist) and
// arrrrny/zuraffa_agent#30 (implements_non_class).
//
// Root cause: `zfa make <Entity> ... datasource` in value-object mode emits
// the mock datasource (`tool_call_signature_mock_datasource.dart`) that imports this file
// and `implements ToolCallSignatureDatasource`, but value-object mode SKIPS emitting
// the datasource file itself — the mock references a file zfa itself decided
// not to emit. The fix surface: ship a hand-curated datasource interface so
// the mock_datasource's import + implements clause resolve.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/tool_call_signature/tool_call_signature.dart';

/// Data-source interface for the ToolCallSignature value object.
///
/// Content-addressable signature of a tool invocation: tool name + argument hash + version. Used by RepetitionTracker and the eval harness to dedupe calls.
abstract class ToolCallSignatureDatasource with Loggable, FailureHandler {
  /// Returns the current state of the ToolCallSignature (single instance — value object).
  Future<ToolCallSignature> current();

  /// Resets the ToolCallSignature state to its initial value.
  Future<void> reset();
}
