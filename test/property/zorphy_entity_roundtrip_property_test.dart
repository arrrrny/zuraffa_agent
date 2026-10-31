// Randomized JSON round-trip property tests for every Zorphy entity —
// issue #128 AC-2 ("at minimum, randomized loop tests for JSON round-trip on
// every Zorphy entity").
//
// Scope: all 18 generated Zorphy entities (lib/src/domain/entities/**/*.zorphy.dart)
// plus the 10 SessionTreeEntry subtypes that wrap them for JSONL persistence
// (lib/src/types.dart), driven through the REAL polymorphic dispatch.
//
// Equality note: the generated `operator ==` compares List/Map fields by
// identity, so these properties assert round-trip fidelity at the JSON level
// — `jsonEncode(fromJson(jsonEncode(toJson(e))).toJson())` must be
// byte-identical
// to `jsonEncode(e.toJson())`. That is the wire contract the codecs actually
// own, and it is strictly stronger than an identity-tainted `==`.
//
// All randomness is seeded (see property_harness.dart) — CI-stable.
library;

import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_spec/agent_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/approval_request/approval_request.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_type/sub_agent_type.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'property_harness.dart';

void main() {
  // ---------------------------------------------------------------------
  // Generators — one per Zorphy entity. Every generator passes explicit
  // timestamps so codecs never hit DateTime.now() (non-deterministic).
  // ---------------------------------------------------------------------

  ArtifactRef genArtifactRef(Random rnd) => ArtifactRef(
    kind: randomNonEmptyString(rnd, maxLength: 8),
    id: 'art-${rnd.nextInt(99999)}',
    uri: rnd.nextBool() ? null : randomString(rnd),
  );

  ApprovalRequest genApprovalRequest(Random rnd) => ApprovalRequest(
    id: 'apr-${rnd.nextInt(99999)}',
    toolName: randomNonEmptyString(rnd, maxLength: 10),
    arguments: randomJsonObject(rnd, maxDepth: 2),
    requestedAt: randomDateTime(rnd),
    timeoutMs: intBetween(rnd, 0, 600000),
  );

  LabelEntry genLabelEntry(Random rnd) => LabelEntry(
    id: 'lbl-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    label: randomNonEmptyString(rnd, maxLength: 10),
  );

  CustomEntry genCustomEntry(Random rnd) => CustomEntry(
    id: 'cus-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    customType: randomNonEmptyString(rnd, maxLength: 8),
    payload: randomString(rnd),
  );

  Model genModel(Random rnd) => Model(
    provider: randomNonEmptyString(rnd, maxLength: 8),
    modelId: randomNonEmptyString(rnd, maxLength: 12),
    contextWindow: intBetween(rnd, 1, 10000000),
  );

  ToolDispatchResult genToolDispatchResult(Random rnd) => ToolDispatchResult(
    success: rnd.nextBool(),
    result: randomString(rnd),
    error: randomString(rnd),
    artifactRefs: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
  );

  TurnRecord genTurnRecord(Random rnd) => TurnRecord(
    id: 'trn-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    turnNumber: intBetween(rnd, 0, 1000),
    messageEntryIds: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++) 'e-msg-$i',
    ],
    toolInvocationEntryIds: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++) 'e-tool-$i',
    ],
    stopReason: randomNonEmptyString(rnd, maxLength: 8),
    startedAt: randomDateTime(rnd),
    endedAt: randomDateTime(rnd),
    durationMs: intBetween(rnd, 0, 1000000),
  );

  ToolInvocationRecord genToolInvocationRecord(Random rnd) =>
      ToolInvocationRecord(
        id: 'tix-${rnd.nextInt(99999)}',
        parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
        timestamp: randomDateTime(rnd),
        toolCallId: randomNonEmptyString(rnd, maxLength: 10),
        toolName: randomNonEmptyString(rnd, maxLength: 10),
        resultEntryId: rnd.nextBool() ? null : 'e-result-${rnd.nextInt(99999)}',
        isError: rnd.nextBool(),
        durationMs: intBetween(rnd, 0, 1000000),
      );

  UsageLedgerEntry genUsageLedgerEntry(Random rnd) => UsageLedgerEntry(
    id: 'usg-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    callId: randomNonEmptyString(rnd, maxLength: 10),
    turnNumber: intBetween(rnd, 0, 1000),
    inputTokens: intBetween(rnd, 0, 1000000),
    outputTokens: intBetween(rnd, 0, 1000000),
    cacheReadTokens: intBetween(rnd, 0, 1000000),
    cacheWriteTokens: intBetween(rnd, 0, 1000000),
  );

  CompactionEntry genCompactionEntry(Random rnd) => CompactionEntry(
    id: 'cmp-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    firstKeptEntryId: randomNonEmptyString(rnd, maxLength: 12),
    tokensBefore: intBetween(rnd, 0, 10000000),
    tokensAfter: intBetween(rnd, 0, 10000000),
  );

  CompactionSummary genCompactionSummary(Random rnd) => CompactionSummary(
    decisions: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomString(rnd, maxLength: 12),
    ],
    toolNames: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
    keyResults: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomString(rnd, maxLength: 12),
    ],
    planState: rnd.nextBool() ? null : randomString(rnd, maxLength: 12),
  );

  BranchSummaryEntry genBranchSummaryEntry(Random rnd) => BranchSummaryEntry(
    id: 'brs-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    summary: randomString(rnd),
  );

  ThinkingLevelChangeEntry genThinkingLevelChangeEntry(Random rnd) =>
      ThinkingLevelChangeEntry(
        id: 'thk-${rnd.nextInt(99999)}',
        parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
        timestamp: randomDateTime(rnd),
        thinkingLevel: randomNonEmptyString(rnd, maxLength: 8),
      );

  ModelChangeEntry genModelChangeEntry(Random rnd) => ModelChangeEntry(
    id: 'mdc-${rnd.nextInt(99999)}',
    parentId: rnd.nextBool() ? null : 'e-parent-${rnd.nextInt(99999)}',
    timestamp: randomDateTime(rnd),
    modelId: randomNonEmptyString(rnd, maxLength: 12),
    provider: randomNonEmptyString(rnd, maxLength: 8),
  );

  GoldenMission genGoldenMission(Random rnd) => GoldenMission(
    id: 'gld-${rnd.nextInt(99999)}',
    name: randomNonEmptyString(rnd, maxLength: 12),
    cassette: randomJsonObject(rnd, maxDepth: 3),
    taskDefinition: randomString(rnd),
    graderBindings: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
  );

  AgentSpec genAgentSpec(Random rnd) => AgentSpec(
    id: 'agt-${rnd.nextInt(99999)}',
    tools: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
    subagents: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
    budget: randomNonEmptyString(rnd, maxLength: 8),
    systemPrompt: randomString(rnd),
    riskTier: randomNonEmptyString(rnd, maxLength: 6),
    extendsSpec: randomNonEmptyString(rnd, maxLength: 8),
  );

  Suite genSuite(Random rnd) => Suite(
    id: 'sui-${rnd.nextInt(99999)}',
    name: randomNonEmptyString(rnd, maxLength: 12),
    tasks: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
    k: intBetween(rnd, 1, 100),
    gateThreshold: rnd.nextDouble(),
  );

  SubAgentType genSubAgentType(Random rnd) => SubAgentType(
    id: 'sat-${rnd.nextInt(99999)}',
    name: randomNonEmptyString(rnd, maxLength: 10),
    specRef: randomNonEmptyString(rnd, maxLength: 10),
    allowlist: [
      for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
        randomNonEmptyString(rnd, maxLength: 8),
    ],
    budgetProfile: randomNonEmptyString(rnd, maxLength: 8),
  );

  // ---------------------------------------------------------------------
  // The round-trip property, parameterized per entity.
  // ---------------------------------------------------------------------

  /// Wire round-trip: toJson → jsonEncode → jsonDecode → fromJson must
  /// reproduce byte-identical JSON on re-serialization.
  void roundTripsOnWire<E extends Object>(
    String entity,
    E Function(Random rnd) make,
    Map<String, dynamic> Function(E entity) toJson,
    E Function(Map<String, dynamic> json) fromJson,
  ) {
    test('$entity: wire round-trip is byte-stable (150 random instances)', () {
      check('$entity JSON round-trip', (rnd, trial) {
        final source = make(rnd);
        final wire = jsonEncode(toJson(source));
        final parsed = fromJson(jsonDecode(wire) as Map<String, dynamic>);
        expect(
          jsonEncode(toJson(parsed)),
          wire,
          reason:
              'trial $trial: $entity round-trip drifted — the re-encoded '
              'form must be byte-identical',
        );
      }, iterations: 150);
    });
  }

  group('Zorphy entity JSON round-trips (seeded, randomized)', () {
    roundTripsOnWire(
      'ArtifactRef',
      genArtifactRef,
      (e) => e.toJson(),
      ArtifactRef.fromJson,
    );
    roundTripsOnWire(
      'ApprovalRequest',
      genApprovalRequest,
      (e) => e.toJson(),
      ApprovalRequest.fromJson,
    );
    roundTripsOnWire(
      'LabelEntry',
      genLabelEntry,
      (e) => e.toJson(),
      LabelEntry.fromJson,
    );
    roundTripsOnWire(
      'CustomEntry',
      genCustomEntry,
      (e) => e.toJson(),
      CustomEntry.fromJson,
    );
    roundTripsOnWire('Model', genModel, (e) => e.toJson(), Model.fromJson);
    roundTripsOnWire(
      'ToolDispatchResult',
      genToolDispatchResult,
      (e) => e.toJson(),
      ToolDispatchResult.fromJson,
    );
    roundTripsOnWire(
      'TurnRecord',
      genTurnRecord,
      (e) => e.toJson(),
      TurnRecord.fromJson,
    );
    roundTripsOnWire(
      'ToolInvocationRecord',
      genToolInvocationRecord,
      (e) => e.toJson(),
      ToolInvocationRecord.fromJson,
    );
    roundTripsOnWire(
      'UsageLedgerEntry',
      genUsageLedgerEntry,
      (e) => e.toJson(),
      UsageLedgerEntry.fromJson,
    );
    roundTripsOnWire(
      'CompactionEntry',
      genCompactionEntry,
      (e) => e.toJson(),
      CompactionEntry.fromJson,
    );
    roundTripsOnWire(
      'CompactionSummary',
      genCompactionSummary,
      (e) => e.toJson(),
      CompactionSummary.fromJson,
    );
    roundTripsOnWire(
      'BranchSummaryEntry',
      genBranchSummaryEntry,
      (e) => e.toJson(),
      BranchSummaryEntry.fromJson,
    );
    roundTripsOnWire(
      'ThinkingLevelChangeEntry',
      genThinkingLevelChangeEntry,
      (e) => e.toJson(),
      ThinkingLevelChangeEntry.fromJson,
    );
    roundTripsOnWire(
      'ModelChangeEntry',
      genModelChangeEntry,
      (e) => e.toJson(),
      ModelChangeEntry.fromJson,
    );
    roundTripsOnWire(
      'GoldenMission',
      genGoldenMission,
      (e) => e.toJson(),
      GoldenMission.fromJson,
    );
    roundTripsOnWire(
      'AgentSpec',
      genAgentSpec,
      (e) => e.toJson(),
      AgentSpec.fromJson,
    );
    roundTripsOnWire('Suite', genSuite, (e) => e.toJson(), Suite.fromJson);
    roundTripsOnWire(
      'SubAgentType',
      genSubAgentType,
      (e) => e.toJson(),
      SubAgentType.fromJson,
    );
  });

  group('SessionTreeEntry polymorphic JSON round-trips (seeded)', () {
    /// Each case builds a wrapped entry; the round-trip goes through the
    /// REAL SessionTreeEntry.fromJson dispatch (the `_type` switch the JSONL
    /// storage relies on), and the decoded entry must land on the same
    /// subclass with byte-identical JSON.
    final cases = <String, SessionTreeEntry Function(Random rnd, int trial)>{
      'MessageEntry': (rnd, trial) => MessageEntry(
        id: 'e-msg-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        message: UserMessage(
          content: [TextBlock(randomString(rnd, maxLength: 24))],
          timestamp: randomDateTime(rnd),
        ),
      ),
      'TurnRecordEntry': (rnd, trial) => TurnRecordEntry(
        id: 'e-trn-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genTurnRecord(rnd),
      ),
      'ToolInvocationEntry': (rnd, trial) => ToolInvocationEntry(
        id: 'e-tix-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genToolInvocationRecord(rnd),
        arguments: randomJsonObject(rnd, maxDepth: 2),
        artifactRefs: [
          for (var i = 0, n = intBetween(rnd, 0, 3); i < n; i++)
            genArtifactRef(rnd),
        ],
      ),
      'UsageEntry': (rnd, trial) => UsageEntry(
        id: 'e-usg-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genUsageLedgerEntry(rnd),
        model: rnd.nextBool() ? null : genModel(rnd),
      ),
      'CompactionTreeEntry': (rnd, trial) => CompactionTreeEntry(
        id: 'e-cmp-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genCompactionEntry(rnd),
        summary: genCompactionSummary(rnd),
      ),
      'ThinkingLevelEntry': (rnd, trial) => ThinkingLevelEntry(
        id: 'e-thk-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genThinkingLevelChangeEntry(rnd),
      ),
      'ModelChangeTreeEntry': (rnd, trial) => ModelChangeTreeEntry(
        id: 'e-mdc-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genModelChangeEntry(rnd),
      ),
      'BranchSummaryTreeEntry': (rnd, trial) => BranchSummaryTreeEntry(
        id: 'e-brs-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genBranchSummaryEntry(rnd),
      ),
      'LabelTreeEntry': (rnd, trial) => LabelTreeEntry(
        id: 'e-lbl-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genLabelEntry(rnd),
      ),
      'CustomTreeEntry': (rnd, trial) => CustomTreeEntry(
        id: 'e-cus-$trial',
        parentId: rnd.nextBool() ? null : 'e-parent-$trial',
        timestamp: randomDateTime(rnd),
        record: genCustomEntry(rnd),
      ),
    };

    for (final entry in cases.entries) {
      test('${entry.key}: wire round-trip through the _type dispatch', () {
        check('${entry.key} session-entry round-trip', (rnd, trial) {
          final source = entry.value(rnd, trial);
          final wire = jsonEncode(source.toJson());
          final parsed = SessionTreeEntry.fromJson(
            jsonDecode(wire) as Map<String, dynamic>,
          );
          expect(
            parsed.runtimeType,
            source.runtimeType,
            reason: 'trial $trial: dispatch must rebuild the same subtype',
          );
          expect(
            jsonEncode(parsed.toJson()),
            wire,
            reason: 'trial $trial: byte-level round-trip drifted',
          );
        }, iterations: 120);
      });
    }
  });
}
