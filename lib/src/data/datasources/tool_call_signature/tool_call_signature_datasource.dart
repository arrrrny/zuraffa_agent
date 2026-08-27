// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#29 (uri_does_not_exist) and
// arrrrny/zuraffa_agent#30 (implements_non_class).
//
// Root cause: `zfa make <Entity> ... datasource` in value-object mode emits
// the mock datasource (`tool_call_signature_mock_datasource.dart`) that imports
// this file and `implements ToolCallSignatureDatasource`, but value-object mode
// SKIPS emitting the datasource file itself — the mock references a file zfa
// itself decided not to emit. The fix surface: ship a hand-curated datasource
// interface so the mock_datasource's import + implements clause resolve.
//
// Refined under specs/29-tool_call_signature-datasource-pair: the interface
// carries the capture/lookup persistence contract used in caching/dedup.
// The scaffolded current() (single-instance read) is subsumed by lookup(key)
// and dropped — documented in the spec's Assumptions.

import 'package:zuraffa/zuraffa.dart';
import '../../../domain/entities/tool_call_signature/tool_call_signature.dart';

/// Data-source interface for the ToolCallSignature value object.
///
/// Content-addressable signature store: the engine captures the signature of
/// every tool invocation and looks it up later to decide whether this exact
/// call (tool name + argument hash + version) was already made — the basis of
/// caching and dedup. The RepetitionTracker (spec 25) consumes the signature's
/// key as its opaque repetition key.
abstract class ToolCallSignatureDatasource with Loggable, FailureHandler {
  /// Captures [signature] into the store, addressed by its content-derived
  /// key. Idempotent per key: capturing content-equal signatures again
  /// overwrites the entry and does not grow the store.
  Future<void> capture(ToolCallSignature signature);

  /// Returns the captured signature addressed by [key], or null when the
  /// key was never captured — a miss is a normal outcome, never an error.
  Future<ToolCallSignature?> lookup(String key);

  /// Returns the number of distinct captured signatures.
  Future<int> count();

  /// Clears every captured signature from the store.
  Future<void> reset();
}
