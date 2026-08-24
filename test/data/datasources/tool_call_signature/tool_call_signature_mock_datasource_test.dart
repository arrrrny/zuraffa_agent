// Regression test for arrrrny/zuraffa_agent#29 + #30.
//
// Verifies the ToolCallSignatureMockDatasource resolves cleanly:
// - import resolves (uri_does_not_exist is gone)
// - implements clause resolves (implements_non_class is gone)
// - mock bodies throw UnimplementedError as designed

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/datasources/tool_call_signature/tool_call_signature_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/tool_call_signature/tool_call_signature_mock_datasource.dart';

void main() {
  group('arrarrny/zuraffa_agent#29 + #30 — ToolCallSignature datasource pair', () {
    test('ToolCallSignatureMockDatasource is a ToolCallSignatureDatasource', () {
      expect(ToolCallSignatureMockDatasource(), isA<ToolCallSignatureDatasource>());
    });

    test('ToolCallSignatureMockDatasource.current throws UnimplementedError', () {
      expect(
        () => ToolCallSignatureMockDatasource().current(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ToolCallSignatureMockDatasource.reset throws UnimplementedError', () {
      expect(
        () => ToolCallSignatureMockDatasource().reset(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
