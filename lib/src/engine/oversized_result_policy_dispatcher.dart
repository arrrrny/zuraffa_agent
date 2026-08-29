// HAND-CURATED — DO NOT REGENERATE VIA zfa.
//
// OversizedResultPolicyDispatcher — a ToolDispatcher decorator that enforces the
// oversized-result threshold on every dispatched result before it reaches the
// mission loop (spec-003 §4.3, FR-005 / R3#3 / SC-003). Mirrors the existing
// AllowlistToolDispatcher decorator shape. Successful results whose body exceeds
// the active OversizedResultPolicy.thresholdBytes are stored via ArtifactService
// and rewritten with a bounded summary + artifactRef; the model never sees the
// full body.

import 'package:zuraffa/zuraffa.dart' show NoParams;

import '../artifact/artifact_service.dart';
import '../artifact/oversized_result_policy_applier.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import '../domain/services/oversized_result_policy_service.dart';
import 'tool_dispatcher.dart';

class OversizedResultPolicyDispatcher implements ToolDispatcher {
  OversizedResultPolicyDispatcher({
    required ToolDispatcher inner,
    required OversizedResultPolicyService policyService,
    required ArtifactService artifactService,
  })  : _inner = inner,
        _policyService = policyService,
        _artifactService = artifactService;

  final ToolDispatcher _inner;
  final OversizedResultPolicyService _policyService;
  final ArtifactService _artifactService;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    final result = await _inner.dispatch(
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
    );
    return _enforce(result);
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async {
    final results = await _inner.dispatchBatch(
      calls: calls,
      isInternalMission: isInternalMission,
    );
    return Future.wait(results.map(_enforce));
  }

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) =>
      _inner.validateSchema(schema: schema, arguments: arguments);

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) =>
      _inner.checkRiskTier(riskTier: riskTier, isInternalMission: isInternalMission);

  Future<ToolDispatchResult> _enforce(ToolDispatchResult result) async {
    final policy = await _policyService.current(NoParams());
    return enforceOversizedResultPolicyOnDispatch(
      result: result,
      policy: policy,
      artifactService: _artifactService,
    );
  }
}
