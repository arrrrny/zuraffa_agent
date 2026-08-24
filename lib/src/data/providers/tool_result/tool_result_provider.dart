// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// Concrete provider stub for the ToolResult data layer. Mirrors the
// ArtifactProvider pattern from PR #32: bodies throw UnimplementedError so
// the file is analyzable without forcing real I/O. Parameterless methods
// (current, count) declare NoParams params so the @override clause matches
// the ToolResultService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_result/tool_result.dart';
import '../../../domain/services/tool_result_service.dart';

class ToolResultProvider with Loggable, FailureHandler implements ToolResultService {
  ToolResultProvider();

  @override
  Future<ToolResult> current(NoParams params) async =>
      throw UnimplementedError('Implement ToolResultProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ToolResultProvider.count');
}
