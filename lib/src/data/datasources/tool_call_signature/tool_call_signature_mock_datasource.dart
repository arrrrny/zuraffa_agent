// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#29 and arrrrny/zuraffa_agent#30.
//
// Mock datasource for the ToolCallSignature value object. Mirrors the zfa-generated
// mock_datasource stub convention (see
// `lib/src/data/datasources/turn_record/turn_record_remote_datasource.dart`
// for the reference shape). Bodies throw UnimplementedError until a real
// store is wired by the consuming application.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/tool_call_signature/tool_call_signature.dart';
import 'tool_call_signature_datasource.dart';

class ToolCallSignatureMockDatasource
    with Loggable, FailureHandler
    implements ToolCallSignatureDatasource {
  ToolCallSignatureMockDatasource();

  @override
  Future<ToolCallSignature> current() async =>
      throw UnimplementedError('Implement ToolCallSignatureMockDatasource.current');

  @override
  Future<void> reset() async =>
      throw UnimplementedError('Implement ToolCallSignatureMockDatasource.reset');
}
