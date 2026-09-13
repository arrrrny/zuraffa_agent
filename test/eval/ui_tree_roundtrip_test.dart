// Spec: issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI) —
// AC-1: ui/tree+json payloads round-trip through session persistence
// and replay identically.
//
// Three independent round-trip layers, each tested in isolation:
// 1. ToolResult boundary: a ui/tree+json payload embedded as
//    `ToolResult.structuredPayload` survives `toJson` → `fromJson`.
// 2. Session tree persistence: a ToolInvocationEntry whose arguments
//    carry the payload survives `toJson` → `fromJson`. This is the
//    layer the engine persists to disk / replays from cassette.
// 3. Replay identity: a payload reconstructed from a persisted entry
//    is deep-equal to the original (no field drift, no tree shape
//    change, no vocabulary/schemaVersion drift).
//
// The cassette replay path (CassetteReplayLlmClient) is already covered
// by spec 006 / cassette_replay tests; this file's layer-3 test
// confirms the payload side of that contract: any payload the engine
// persists is replayable as the deep-equal original.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_result/tool_result.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';
import 'package:zuraffa_agent/src/types.dart';

UiTreePayload _originalPayload() => UiTreePayload(
  vocabularyId: 'shadcn-ui@1.0.0',
  schemaVersion: '1.0.0',
  tree: {
    'type': 'Column',
    'props': {'padding': 8},
    'children': [
      {
        'type': 'Text',
        'props': {'value': 'hi'},
      },
      {
        'type': 'Row',
        'children': [
          {'type': 'Text'},
          {'type': 'Text'},
        ],
      },
    ],
  },
);

void main() {
  group('issue #8 AC-1 — ui/tree+json round-trip through ToolResult', () {
    test(
      'payload embedded as structuredPayload survives ToolResult round-trip',
      () {
        final original = _originalPayload();
        final toolResult = ToolResult.success(
          content: 'rendered',
          structuredPayload: original.toJson(),
        );

        // Serialize → deserialize the ToolResult.
        final json = toolResult.toJson();
        final restored = ToolResult.fromJson(json);

        // The structuredPayload map is preserved.
        expect(restored.structuredPayload, isNotNull);
        // Reconstruct the UiTreePayload from the restored map and verify
        // deep equality with the original.
        final restoredPayload = UiTreePayload.fromJson(
          restored.structuredPayload!,
        );
        expect(restoredPayload, original);
      },
    );

    test('payload round-trips through JSON string encoding (wire format)', () {
      final original = _originalPayload();
      final wire = jsonEncode(original.toJson());
      final restoredPayload = UiTreePayload.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );
      expect(restoredPayload, original);
    });

    test(
      'payload mimeType is preserved as "ui/tree+json" across the round-trip',
      () {
        final original = _originalPayload();
        final wire = jsonEncode(original.toJson());
        final restored = UiTreePayload.fromJson(
          jsonDecode(wire) as Map<String, dynamic>,
        );
        expect(UiTreePayload.mimeType, 'ui/tree+json');
        expect(restored.toJson()['mimeType'], 'ui/tree+json');
      },
    );

    test('depth and nodeCount are recomputed identically after round-trip', () {
      final original = _originalPayload();
      final wire = jsonEncode(original.toJson());
      final restored = UiTreePayload.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );
      expect(restored.depth, original.depth);
      expect(restored.nodeCount, original.nodeCount);
    });
  });

  group('issue #8 AC-1 — ui/tree+json round-trip through session persistence', () {
    test(
      'payload embedded as ToolInvocationEntry.arguments survives round-trip',
      () {
        final original = _originalPayload();

        // Build a ToolInvocationEntry whose arguments carry the payload
        // under the `uiTree` key (the shape a `ui.render` tool would
        // record). This is the layer the engine persists to disk and
        // replays from cassette.
        final entry = ToolInvocationEntry(
          id: 'e_1',
          parentId: null,
          timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
          record: ToolInvocationRecord(
            id: 'ti_1',
            parentId: null,
            timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
            toolCallId: 'tc_1',
            toolName: 'ui.render',
            isError: false,
            durationMs: 500,
          ),
          arguments: {'uiTree': original.toJson()},
        );

        // Serialize → deserialize the session tree entry.
        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json) as ToolInvocationEntry;

        // The arguments map survived.
        expect(restored.arguments, contains('uiTree'));
        // Reconstruct the payload and verify deep equality with the original.
        final restoredPayload = UiTreePayload.fromJson(
          restored.arguments['uiTree'] as Map<String, dynamic>,
        );
        expect(restoredPayload, original);
      },
    );

    test(
      'payload survives a double round-trip (persist → load → persist → load)',
      () {
        final original = _originalPayload();
        final entry = ToolInvocationEntry(
          id: 'e_1',
          parentId: null,
          timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
          record: ToolInvocationRecord(
            id: 'ti_1',
            parentId: null,
            timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
            toolCallId: 'tc_1',
            toolName: 'ui.render',
            isError: false,
            durationMs: 500,
          ),
          arguments: {'uiTree': original.toJson()},
        );

        final json1 = entry.toJson();
        final restored1 =
            SessionTreeEntry.fromJson(json1) as ToolInvocationEntry;
        final json2 = restored1.toJson();

        // JSON is byte-stable across the double round-trip.
        expect(json2, json1);

        // And the payload is still deep-equal to the original.
        final restoredPayload = UiTreePayload.fromJson(
          (restored1.arguments['uiTree'] as Map<String, dynamic>),
        );
        expect(restoredPayload, original);
      },
    );

    test(
      'payload survives round-trip inside a ToolInvocationEntry with extra args',
      () {
        // A real `ui.render` tool call records the payload alongside other
        // arguments (render-hint, request-id, etc.). This test confirms
        // the payload survives even when the surrounding arguments map
        // carries unrelated keys.
        final original = _originalPayload();
        final entry = ToolInvocationEntry(
          id: 'e_1',
          parentId: null,
          timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
          record: ToolInvocationRecord(
            id: 'ti_1',
            parentId: null,
            timestamp: DateTime.utc(2026, 9, 2, 12, 0, 0),
            toolCallId: 'tc_1',
            toolName: 'ui.render',
            isError: false,
            durationMs: 500,
          ),
          arguments: {
            'uiTree': original.toJson(),
            'renderHint': 'prefer-light',
            'requestId': 'req-abc-123',
          },
        );

        final json = entry.toJson();
        final restored = SessionTreeEntry.fromJson(json) as ToolInvocationEntry;

        // Unrelated args survive.
        expect(restored.arguments['renderHint'], 'prefer-light');
        expect(restored.arguments['requestId'], 'req-abc-123');
        // Payload survives and is deep-equal to the original.
        final restoredPayload = UiTreePayload.fromJson(
          restored.arguments['uiTree'] as Map<String, dynamic>,
        );
        expect(restoredPayload, original);
      },
    );
  });

  group('issue #8 AC-1 — replay identity (no drift after persistence)', () {
    test('reconstructed payload has identical toJson() to the original', () {
      final original = _originalPayload();
      final wire = jsonEncode(original.toJson());
      final restored = UiTreePayload.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );

      // toJson() is the contract surface the eval harness compares;
      // byte-identical toJson means replay is identical.
      expect(restored.toJson(), original.toJson());
    });

    test('reconstructed payload diff against original reports no changes', () {
      final original = _originalPayload();
      final wire = jsonEncode(original.toJson());
      final restored = UiTreePayload.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );

      final diff = original.diff(restored);
      expect(diff.hasChanges, isFalse);
      expect(diff.addedPaths, isEmpty);
      expect(diff.removedPaths, isEmpty);
      expect(diff.changedPaths, isEmpty);
      expect(diff.vocabularyChanged, isFalse);
      expect(diff.schemaChanged, isFalse);
    });

    test(
      'payload with non-string tree values (null/bool/num) round-trips identically',
      () {
        // Tree containing null/bool/num values — preserves plain-JSON-map
        // contract per spec 038 edge cases.
        final original = UiTreePayload(
          vocabularyId: 'shadcn-ui@1.0.0',
          schemaVersion: '1.0.0',
          tree: {
            'type': 'Column',
            'props': {
              'nullVal': null,
              'boolVal': true,
              'intVal': 42,
              'doubleVal': 3.14,
              'stringVal': 'hello',
            },
          },
        );
        final wire = jsonEncode(original.toJson());
        final restored = UiTreePayload.fromJson(
          jsonDecode(wire) as Map<String, dynamic>,
        );
        expect(restored, original);
      },
    );
  });
}
