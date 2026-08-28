// HAND-CURATED regression tests for the ToolDispatchMode value object +
// ToolDispatchModeProvider. Pattern mirrors spec 033.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_mode/tool_dispatch_mode.dart';
import 'package:zuraffa_agent/src/domain/services/tool_dispatch_mode_service.dart';
import 'package:zuraffa_agent/src/data/providers/tool_dispatch_mode/tool_dispatch_mode_provider.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';

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

    test('ToolDispatchMode inequality detected per-field: id', () {
      final a = ToolDispatchMode(id: 'id-1', mode: 'sequential', maxParallel: 1, failFast: false);
      final b = ToolDispatchMode(id: 'id-2', mode: 'sequential', maxParallel: 1, failFast: false);
      expect(a == b, isFalse);
    });

    test('ToolDispatchMode inequality detected per-field: mode', () {
      final a = ToolDispatchMode(id: 'id', mode: 'sequential', maxParallel: 1, failFast: false);
      final b = ToolDispatchMode(id: 'id', mode: 'parallel', maxParallel: 1, failFast: false);
      expect(a == b, isFalse);
    });

    test('ToolDispatchMode inequality detected per-field: maxParallel', () {
      final a = ToolDispatchMode(id: 'id', mode: 'sequential', maxParallel: 1, failFast: false);
      final b = ToolDispatchMode(id: 'id', mode: 'sequential', maxParallel: 5, failFast: false);
      expect(a == b, isFalse);
    });

    test('ToolDispatchMode inequality detected per-field: failFast', () {
      final a = ToolDispatchMode(id: 'id', mode: 'sequential', maxParallel: 1, failFast: true);
      final b = ToolDispatchMode(id: 'id', mode: 'sequential', maxParallel: 1, failFast: false);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolDispatchMode toString', () {
    test('toString includes id, mode, and maxParallel', () {
      final m = ToolDispatchMode(id: 'dispatch-1', mode: 'parallel', maxParallel: 8, failFast: true);
      final s = m.toString();
      expect(s, contains('dispatch-1'));
      expect(s, contains('parallel'));
      expect(s, contains('8'));
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

  group('arrarrny/zuraffa_agent#4 - Engine ToolDispatcher interface', () {
    test('ToolCall holds toolName, arguments, executionMode', () {
      const call = ToolCall(
        toolName: 'fs.read',
        arguments: {'path': '/tmp'},
        executionMode: 'sequential',
      );
      expect(call.toolName, 'fs.read');
      expect(call.arguments, {'path': '/tmp'});
      expect(call.executionMode, 'sequential');
    });

    test('ToolCall const constructor', () {
      const call = ToolCall(
        toolName: 'web.fetch',
        arguments: {},
        executionMode: 'parallel',
      );
      expect(call, isA<ToolCall>());
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolDispatchResult (Zorphy codegen)', () {
    test('ToolDispatchResult round-trips through JSON with all 4 fields', () {
      final result = ToolDispatchResult(
        success: true,
        result: 'file contents here',
        error: '',
        artifactRefs: ['art-1', 'art-2'],
      );
      final json = result.toJson();
      final restored = ToolDispatchResult.fromJson(json);
      expect(restored.success, result.success);
      expect(restored.result, result.result);
      expect(restored.error, result.error);
      expect(restored.artifactRefs, result.artifactRefs);
    });

    test('ToolDispatchResult error round-trip', () {
      final result = ToolDispatchResult(
        success: false,
        result: '',
        error: 'permission denied',
        artifactRefs: [],
      );
      final json = result.toJson();
      final restored = ToolDispatchResult.fromJson(json);
      expect(restored.success, isFalse);
      expect(restored.error, 'permission denied');
      expect(restored.artifactRefs, isEmpty);
    });

    test('ToolDispatchResult.copyWith produces new instance', () {
      final a = ToolDispatchResult(success: true, result: 'ok', error: '', artifactRefs: []);
      final b = a.copyWith(success: false, error: 'fail');
      expect(b.success, isFalse);
      expect(b.error, 'fail');
      // original unchanged
      expect(a.success, isTrue);
      expect(a.error, '');
    });

    test('ToolDispatchResult hasResult / noResult helpers', () {
      final withResult = ToolDispatchResult(success: true, result: 'data', error: '', artifactRefs: []);
      final noResult = ToolDispatchResult(success: false, result: '', error: 'err', artifactRefs: []);
      expect(withResult.hasResult, isTrue);
      expect(withResult.noResult, isFalse);
      expect(noResult.hasResult, isFalse);
      expect(noResult.noResult, isTrue);
    });

    test('ToolDispatchResult hasError / noError helpers', () {
      final withError = ToolDispatchResult(success: false, result: '', error: 'boom', artifactRefs: []);
      final noError = ToolDispatchResult(success: true, result: 'ok', error: '', artifactRefs: []);
      expect(withError.hasError, isTrue);
      expect(withError.noError, isFalse);
      expect(noError.hasError, isFalse);
      expect(noError.noError, isTrue);
    });

    test('ToolDispatchResult JSON encoding produces all keys', () {
      final result = ToolDispatchResult(
        success: true,
        result: 'r',
        error: 'e',
        artifactRefs: ['a'],
      );
      final json = result.toJson();
      expect(json, containsPair('success', true));
      expect(json, containsPair('result', 'r'));
      expect(json, containsPair('error', 'e'));
      expect(json, containsPair('artifactRefs', ['a']));
    });
  });
}
