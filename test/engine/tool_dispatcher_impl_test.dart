// Tests for ToolDispatcherImpl — Spec 003: Tools & MCP
//
// Covers:
// - JSON Schema validation (FR-002)
// - Risk tier enforcement (FR-003, User Story 2)
// - Sequential/parallel dispatch (FR-002, User Story 1)
// - Artifact size discipline (FR-005, User Story 4)
// - Tool not found handling

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/enums/risk_tier.dart';
import 'package:zuraffa_agent/src/domain/entities/enums/execution_mode.dart';
import 'package:zuraffa_agent/src/domain/entities/enums/tool_source.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher_impl.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart';
import 'package:zuraffa_agent/src/artifact/artifact_service.dart';
import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockToolRegistry extends Mock implements ToolRegistry {}

class MockArtifactService extends Mock implements ArtifactService {}

class FakeAgentTool extends Fake implements AgentTool {
  FakeAgentTool({
    required this.name,
    this.riskTier = RiskTier.safe,
    this.executionMode = ExecutionMode.sequential,
    this.inputSchema = const {},
  });

  @override
  final String name;

  @override
  final RiskTier riskTier;

  @override
  final ExecutionMode executionMode;

  @override
  final Map<String, dynamic> inputSchema;

  @override
  String get id => 'tool-$name';

  @override
  String get description => 'Test tool: $name';

  @override
  ToolSource get source => ToolSource.dda;

  @override
  String? get transportBinding => null;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late ToolDispatcherImpl dispatcher;
  late MockToolRegistry mockRegistry;
  late MockArtifactService mockArtifactService;

  setUp(() {
    mockRegistry = MockToolRegistry();
    mockArtifactService = MockArtifactService();
    dispatcher = ToolDispatcherImpl(
      registry: mockRegistry,
      artifactService: mockArtifactService,
    );

    // Default: artifact service returns non-summarized result
    when(() => mockArtifactService.store(
          data: any(named: 'data'),
          mimeType: any(named: 'mimeType'),
        )).thenAnswer((_) async => ArtifactStoreResult(
          ref: ArtifactRef(
            id: 'art-1',
            mimeType: 'application/json',
            sizeBytes: 100,
            createdAt: DateTime.now(),
          ),
          summarized: false,
        ));
  });

  group('ToolDispatcherImpl - Tool Not Found', () {
    test('returns error when tool is not in registry', () async {
      when(() => mockRegistry.resolve('unknown_tool'))
          .thenAnswer((_) async => null);

      final result = await dispatcher.dispatch(
        toolName: 'unknown_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Tool not found'));
    });
  });

  group('ToolDispatcherImpl - Schema Validation (FR-002)', () {
    test('passes validation for valid arguments', () async {
      final tool = FakeAgentTool(
        name: 'search',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
          'required': ['query'],
        },
      );
      when(() => mockRegistry.resolve('search'))
          .thenAnswer((_) async => tool);

      final result = await dispatcher.dispatch(
        toolName: 'search',
        arguments: {'query': 'test'},
        isInternalMission: false,
      );

      expect(result.success, isTrue);
    });

    test('returns validation error for missing required field', () async {
      final tool = FakeAgentTool(
        name: 'search',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
          'required': ['query'],
        },
      );
      when(() => mockRegistry.resolve('search'))
          .thenAnswer((_) async => tool);

      final result = await dispatcher.dispatch(
        toolName: 'search',
        arguments: {}, // Missing required 'query'
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Validation failed'));
    });

    test('returns validation error for wrong type', () async {
      final tool = FakeAgentTool(
        name: 'search',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
      );
      when(() => mockRegistry.resolve('search'))
          .thenAnswer((_) async => tool);

      final result = await dispatcher.dispatch(
        toolName: 'search',
        arguments: {'query': 123}, // Wrong type: int instead of string
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Validation failed'));
    });

    test('validateSchema returns empty list for valid args', () {
      final errors = dispatcher.validateSchema(
        schema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
        },
        arguments: {'name': 'Alice'},
      );

      expect(errors, isEmpty);
    });

    test('validateSchema returns errors for invalid args', () {
      final errors = dispatcher.validateSchema(
        schema: {
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
          'required': ['count'],
        },
        arguments: {'count': 'not-a-number'},
      );

      expect(errors, isNotEmpty);
    });
  });

  group('ToolDispatcherImpl - Risk Tiers (FR-003)', () {
    test('safe tier always passes risk check', () {
      expect(
        dispatcher.checkRiskTier(riskTier: 'safe', isInternalMission: false),
        isTrue,
      );
      expect(
        dispatcher.checkRiskTier(riskTier: 'safe', isInternalMission: true),
        isTrue,
      );
    });

    test('confirm tier passes risk check (approval handled at dispatch)', () {
      expect(
        dispatcher.checkRiskTier(riskTier: 'confirm', isInternalMission: false),
        isTrue,
      );
    });

    test('admin tier only passes for internal missions', () {
      expect(
        dispatcher.checkRiskTier(riskTier: 'admin', isInternalMission: true),
        isTrue,
      );
      expect(
        dispatcher.checkRiskTier(riskTier: 'admin', isInternalMission: false),
        isFalse,
      );
    });

    test('admin tier denied on non-internal mission', () async {
      final tool = FakeAgentTool(
        name: 'admin_tool',
        riskTier: RiskTier.admin,
      );
      when(() => mockRegistry.resolve('admin_tool'))
          .thenAnswer((_) async => tool);

      final result = await dispatcher.dispatch(
        toolName: 'admin_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Risk tier'));
      expect(result.error, contains('not allowed'));
    });

    test('admin tier allowed on internal mission', () async {
      final tool = FakeAgentTool(
        name: 'admin_tool',
        riskTier: RiskTier.admin,
      );
      when(() => mockRegistry.resolve('admin_tool'))
          .thenAnswer((_) async => tool);

      final result = await dispatcher.dispatch(
        toolName: 'admin_tool',
        arguments: {},
        isInternalMission: true,
      );

      expect(result.success, isTrue);
    });

    test('confirm tier awaits approval callback', () async {
      final tool = FakeAgentTool(
        name: 'confirm_tool',
        riskTier: RiskTier.confirm,
      );
      when(() => mockRegistry.resolve('confirm_tool'))
          .thenAnswer((_) async => tool);

      // Default callback denies
      final result = await dispatcher.dispatch(
        toolName: 'confirm_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Approval denied'));
    });

    test('confirm tier approves when callback returns true', () async {
      final tool = FakeAgentTool(
        name: 'confirm_tool',
        riskTier: RiskTier.confirm,
      );
      when(() => mockRegistry.resolve('confirm_tool'))
          .thenAnswer((_) async => tool);

      // Create dispatcher with approve-all callback
      final approveDispatcher = ToolDispatcherImpl(
        registry: mockRegistry,
        artifactService: mockArtifactService,
        approvalCallback: (_) async => true,
      );

      final result = await approveDispatcher.dispatch(
        toolName: 'confirm_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isTrue);
    });
  });

  group('ToolDispatcherImpl - Batch Dispatch (FR-002)', () {
    test('dispatches sequential calls in order', () async {
      final tool = FakeAgentTool(name: 'seq_tool');
      when(() => mockRegistry.resolve('seq_tool'))
          .thenAnswer((_) async => tool);

      final calls = List.generate(
        3,
        (i) => ToolCall(
          toolName: 'seq_tool',
          arguments: {'index': i},
          executionMode: ExecutionMode.sequential.name,
        ),
      );

      final results = await dispatcher.dispatchBatch(
        calls: calls,
        isInternalMission: false,
      );

      expect(results, hasLength(3));
      expect(results.every((r) => r.success), isTrue);
    });

    test('dispatches parallel calls concurrently', () async {
      final tool = FakeAgentTool(
        name: 'par_tool',
        executionMode: ExecutionMode.parallel,
      );
      when(() => mockRegistry.resolve('par_tool'))
          .thenAnswer((_) async => tool);

      final calls = List.generate(
        5,
        (i) => ToolCall(
          toolName: 'par_tool',
          arguments: {'index': i},
          executionMode: ExecutionMode.parallel.name,
        ),
      );

      final results = await dispatcher.dispatchBatch(
        calls: calls,
        isInternalMission: false,
      );

      expect(results, hasLength(5));
      expect(results.every((r) => r.success), isTrue);
    });

    test('handles mixed sequential and parallel calls', () async {
      final seqTool = FakeAgentTool(name: 'seq_tool');
      final parTool = FakeAgentTool(
        name: 'par_tool',
        executionMode: ExecutionMode.parallel,
      );
      when(() => mockRegistry.resolve('seq_tool'))
          .thenAnswer((_) async => seqTool);
      when(() => mockRegistry.resolve('par_tool'))
          .thenAnswer((_) async => parTool);

      final calls = [
        ToolCall(
          toolName: 'seq_tool',
          arguments: {},
          executionMode: ExecutionMode.sequential.name,
        ),
        ToolCall(
          toolName: 'par_tool',
          arguments: {},
          executionMode: ExecutionMode.parallel.name,
        ),
        ToolCall(
          toolName: 'par_tool',
          arguments: {},
          executionMode: ExecutionMode.parallel.name,
        ),
      ];

      final results = await dispatcher.dispatchBatch(
        calls: calls,
        isInternalMission: false,
      );

      expect(results, hasLength(3));
    });
  });

  group('ToolDispatcherImpl - Artifact Size Discipline (FR-005)', () {
    test('returns result directly when within threshold', () async {
      final tool = FakeAgentTool(name: 'small_tool');
      when(() => mockRegistry.resolve('small_tool'))
          .thenAnswer((_) async => tool);

      // Artifact service returns non-summarized
      when(() => mockArtifactService.store(
            data: any(named: 'data'),
            mimeType: any(named: 'mimeType'),
          )).thenAnswer((_) async => ArtifactStoreResult(
            ref: ArtifactRef(
              id: 'art-1',
              mimeType: 'application/json',
              sizeBytes: 100,
              createdAt: DateTime.now(),
            ),
            summarized: false,
          ));

      final result = await dispatcher.dispatch(
        toolName: 'small_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(result.artifactRefs, isEmpty);
    });

    test('returns summary + artifactRef when oversized', () async {
      final tool = FakeAgentTool(name: 'big_tool');
      when(() => mockRegistry.resolve('big_tool'))
          .thenAnswer((_) async => tool);

      // Artifact service returns summarized result
      when(() => mockArtifactService.store(
            data: any(named: 'data'),
            mimeType: any(named: 'mimeType'),
          )).thenAnswer((_) async => ArtifactStoreResult(
            ref: ArtifactRef(
              id: 'art-large',
              mimeType: 'application/json',
              sizeBytes: 2 * 1024 * 1024, // 2 MB
              createdAt: DateTime.now(),
            ),
            summarized: true,
            summary: 'Artifact Summary: 2 MB result stored.',
          ));

      final result = await dispatcher.dispatch(
        toolName: 'big_tool',
        arguments: {},
        isInternalMission: false,
      );

      expect(result.success, isTrue);
      expect(result.result, contains('Artifact Summary'));
      expect(result.artifactRefs, contains('art-large'));
    });
  });
}
