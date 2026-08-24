// HAND-CURATED regression tests for the DispatchTool value object +
// DispatchToolProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/dispatch_tool/dispatch_tool.dart';
import 'package:zuraffa_agent/src/domain/services/dispatch_tool_service.dart';
import 'package:zuraffa_agent/src/data/providers/dispatch_tool/dispatch_tool_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 - DispatchTool value equality', () {
    test('DispatchTool equality is value-based across all fields', () {
      final a = DispatchTool(id: 'id-a', toolName: 'dispatch', subAgentSpecId: 'ref-1', riskTier: 'safe');
      final b = DispatchTool(id: 'id-a', toolName: 'dispatch', subAgentSpecId: 'ref-1', riskTier: 'safe');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('DispatchTool inequality differs when a field changes', () {
      final a = DispatchTool(id: 'id-a', toolName: 'dispatch', subAgentSpecId: 'ref-1', riskTier: 'safe');
      final b = DispatchTool(id: 'id-b', toolName: 'dispatch', subAgentSpecId: 'ref-2', riskTier: 'safe');
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 - DispatchTool clean-arch layers', () {
    test('DispatchToolProvider is a DispatchToolService', () {
      final provider = DispatchToolProvider();
      expect(provider, isA<DispatchToolService>());
    });

    test('DispatchToolProvider.current throws UnimplementedError on NoParams', () {
      final provider = DispatchToolProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('DispatchToolProvider.count throws UnimplementedError on NoParams', () {
      final provider = DispatchToolProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
