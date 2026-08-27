// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// Concrete provider for the ToolResult data layer. Keeps the active
// mission's emitted tool results in memory: `current` returns the
// last-emitted result (or a constructed empty default when nothing has
// been emitted) and `count` returns the number of emitted results.
// Mirrors the ProviderConfigProvider / EngineLoopProvider pattern
// (spec 052 / 045).

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_result/tool_result.dart';
import '../../../domain/services/tool_result_service.dart';

class ToolResultProvider with Loggable, FailureHandler implements ToolResultService {
  /// Default result returned when no tool result has been emitted yet.
  static const ToolResult empty = ToolResult(content: '');

  final List<ToolResult> _results;

  ToolResultProvider([List<ToolResult>? results])
      : _results = List<ToolResult>.of(results ?? const <ToolResult>[]);

  /// Records [result] as the latest emitted tool result and returns it.
  ToolResult emit(ToolResult result) {
    _results.add(result);
    return result;
  }

  @override
  Future<ToolResult> current(NoParams params) async =>
      _results.isEmpty ? empty : _results.last;

  @override
  Future<int> count(NoParams params) async => _results.length;
}
