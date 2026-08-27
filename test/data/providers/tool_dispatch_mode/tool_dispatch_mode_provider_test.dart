// HAND-CURATED regression tests for the ToolDispatchMode value object +
// ToolDispatchModeProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart';
import 'package:zuraffa_agent/src/domain/services/tool_dispatch_mode_service.dart';
import 'package:zuraffa_agent/src/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#4 - ToolDispatchMode value equality', () {
    test('ToolDispatchMode equality is value-based across all fields', () {
      final a = ToolDispatchMode(id: 'id-a', mode: 'sequential', maxParallel: 10, failFast: true);
      final b = ToolDispatchMode(id: 'id-a', mode: 'sequential', maxParallel: 10, failFast: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ToolDispatchMode inequality differs when a field changes', () {
      final a = ToolDispatchMode(id: 'id-a', mode: 'sequential', maxParallel: 10, failFast: true);
      final b = ToolDispatchMode(id: 'id-b', mode: 'parallel', maxParallel: 20, failFast: false);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolDispatchMode clean-arch layers', () {
    test('ToolDispatchModeProvider is a ToolDispatchModeService', () {
      expect(ToolDispatchModeProvider(), isA<ToolDispatchModeService>());
    });

    test('ToolDispatchModeProvider.current returns the active dispatch mode', () async {
      final mode = await ToolDispatchModeProvider().current(NoParams());
      expect(mode, isA<ToolDispatchMode>());
      expect(mode.mode, 'sequential');
      expect(mode.maxParallel, greaterThan(0));
    });

    test('ToolDispatchModeProvider.count returns 1', () async {
      expect(await ToolDispatchModeProvider().count(NoParams()), 1);
    });
  });
}
