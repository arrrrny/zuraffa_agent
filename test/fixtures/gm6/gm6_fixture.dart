// GM-6 fixture — dws_playground (issue #8 §4: "golden-mission GM-6
// (dws_playground) uses this").
//
// Headless golden mission for the UI-tree graders: a pinned [UiSpec]
// vocabulary + a pinned canonical snapshot + an "emitted" payload (the
// tree the agent would have rendered in a real run). The eval harness
// runs the schema + snapshot graders against the emitted payload; both
// must pass for the golden to stay green.
//
// Pure Dart, no I/O — the fixture is the in-memory shape the cassette
// would have serialized. A real cassette would store the emitted
// payload as `tool_results[i].structuredPayload`; this fixture exposes
// it directly so the graders can be exercised without the cassette
// machinery (which is itself covered by spec 006 / cassette_replay tests).

import 'package:zuraffa_agent/src/domain/entities/ui_spec/ui_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';
import 'package:zuraffa_agent/src/eval/ui_graders/ui_graders.dart';

/// The in-memory GM-6 fixture (dws_playground).
class Gm6Fixture {
  /// The pinned spec: shadcn-ui@1.0.0, Column/Row/Text allowed, depth ≤ 4,
  /// node count ≤ 12. This is the vocabulary the agent's spec declared.
  final UiSpec pinnedSpec;

  /// The canonical JSON snapshot of the expected emitted payload
  /// (byte-stable: sorted keys at every level, no padding). Stored as a
  /// string so a future run can compare byte-for-byte without
  /// re-canonicalizing the expected side.
  final String pinnedCanonicalSnapshot;

  /// The payload the agent emitted in the recorded run. Graded against
  /// [pinnedSpec] (schema grader) and [pinnedCanonicalSnapshot]
  /// (snapshot grader).
  final UiTreePayload emittedPayload;

  Gm6Fixture._({
    required this.pinnedSpec,
    required this.pinnedCanonicalSnapshot,
    required this.emittedPayload,
  });
}

/// The shared GM-6 fixture instance (dws_playground).
///
/// The pinned spec is shadcn-ui@1.0.0 with three allowed components
/// (Column, Row, Text) and depth/nodes caps of 4 and 12. The emitted
/// tree is a 3-level / 5-node Column → [Text, Row → [Text, Text]] —
/// the canonical "hello world" generative-UI shape — which is in-pin
/// and matches the pinned snapshot exactly.
final Gm6Fixture gm6Fixture = () {
  final pinnedSpec = UiSpec(
    vocabulary: 'shadcn-ui@1.0.0',
    allowedComponents: const ['Column', 'Row', 'Text'],
    caps: const UiCaps(depth: 4, nodes: 12),
  );
  final emittedPayload = UiTreePayload(
    vocabularyId: 'shadcn-ui@1.0.0',
    schemaVersion: '1.0.0',
    tree: {
      'type': 'Column',
      'props': {'padding': 8},
      'children': [
        {
          'type': 'Text',
          'props': {'value': 'Hello'},
        },
        {
          'type': 'Row',
          'children': [
            {
              'type': 'Text',
              'props': {'value': 'A'},
            },
            {
              'type': 'Text',
              'props': {'value': 'B'},
            },
          ],
        },
      ],
    },
  );
  return Gm6Fixture._(
    pinnedSpec: pinnedSpec,
    pinnedCanonicalSnapshot: UiSnapshotGrader.canonicalize(
      emittedPayload.toJson(),
    ),
    emittedPayload: emittedPayload,
  );
}();
