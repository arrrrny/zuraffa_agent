// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#29 and arrrrny/zuraffa_agent#30.
//
// Mock datasource for the ToolCallSignature value object — the in-memory
// reference implementation of the ToolCallSignatureDatasource persistence
// contract (specs/29-tool_call_signature-datasource-pair). A key-addressed
// map: capture overwrites per key (idempotent), lookup misses return null,
// count is the map length, reset clears everything.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_call_signature/tool_call_signature.dart';
import 'tool_call_signature_datasource.dart';

/// In-memory [ToolCallSignatureDatasource].
///
/// Suitable as the reference implementation for tests and as the wiring
/// target until a Hive- or remote-backed datasource exists.
class ToolCallSignatureMockDatasource
    with Loggable, FailureHandler
    implements ToolCallSignatureDatasource {
  ToolCallSignatureMockDatasource();

  /// Captured signatures addressed by their content-derived key.
  final Map<String, ToolCallSignature> _store = {};

  @override
  Future<void> capture(ToolCallSignature signature) async {
    _store[signature.key] = signature;
  }

  @override
  Future<ToolCallSignature?> lookup(String key) async => _store[key];

  @override
  Future<int> count() async => _store.length;

  @override
  Future<void> reset() async {
    _store.clear();
  }
}
