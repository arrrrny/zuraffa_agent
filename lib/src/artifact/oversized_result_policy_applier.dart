// HAND-CURATED — DO NOT REGENERATE VIA zfa.
//
// Enforces the OversizedResultPolicy on a raw tool result: when the result body
// exceeds [OversizedResultPolicy.thresholdBytes], the full body is stored via
// [ArtifactService] and the result is rewritten as an oversized result carrying
// the resulting [ArtifactRef] + a bounded summary (spec-003 §4.3, FR-005). This
// keeps large tool bodies out of model context while keeping the data retrievable.

import 'dart:convert';

import '../domain/entities/oversized_result_policy/oversized_result_policy.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import '../domain/entities/tool_result/tool_result.dart';
import 'artifact_service.dart';

/// Applies [policy] to [result]. Returns [result] unchanged when its UTF-8 byte
/// length is at or below [policy.thresholdBytes]; otherwise stores the body and
/// returns a summarized [ToolResult] with the [ArtifactRef].
Future<ToolResult> enforceOversizedResultPolicy({
  required ToolResult result,
  required OversizedResultPolicy policy,
  required ArtifactService artifactService,
  String mimeType = 'text/plain',
}) async {
  final bytes = utf8.encode(result.content);
  if (bytes.length <= policy.thresholdBytes) return result;

  final stored = await artifactService.store(data: bytes, mimeType: mimeType);
  return ToolResult.oversized(
    summary: stored.summary ?? result.content,
    artifactRef: stored.ref,
    structuredPayload: result.structuredPayload,
    isError: result.isError,
  );
}

/// Applies [policy] to a dispatched [ToolDispatchResult] — the loop-facing half
/// of the oversized-result discipline (spec-003 §4.3, FR-005).
///
/// When a *successful* result's `result` body exceeds [policy.thresholdBytes],
/// the full body is stored via [artifactService] and the result is rewritten
/// with a bounded [summary] and the artifact's id appended to [artifactRefs];
/// error results are never summarized. Returns [result] unchanged otherwise.
Future<ToolDispatchResult> enforceOversizedResultPolicyOnDispatch({
  required ToolDispatchResult result,
  required OversizedResultPolicy policy,
  required ArtifactService artifactService,
  String mimeType = 'text/plain',
}) async {
  if (!result.success) return result;
  final bytes = utf8.encode(result.result);
  if (bytes.length <= policy.thresholdBytes) return result;

  final stored = await artifactService.store(data: bytes, mimeType: mimeType);
  return result.copyWith(
    result: stored.summary ?? result.result,
    artifactRefs: [...result.artifactRefs, stored.ref.id],
  );
}
