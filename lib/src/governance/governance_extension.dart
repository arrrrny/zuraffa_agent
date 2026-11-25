/// The Zuraffa governance extension over pi (FR-001, FR-002, FR-003,
/// contracts/governance-hooks.md).
///
/// [GovernanceExtension.create] turns a [GovernancePolicy] plus the host's
/// telemetry/artifact/approval ports into a [ZuraffaExtension] whose hooks ride
/// pi's real surfaces:
///
///  - `beforeToolCall` — default-deny, deny-list, risk tier, approval gate
///    (denial happens BEFORE execution, SC-001/SC-003).
///  - `afterToolCall` — PII scrubbing, fail-closed sanitizer, oversized-result
///    artifact routing (the model never sees unredacted or oversized bytes,
///    SC-002/SC-007).
///  - `transformContext` — the provider-request egress seam: scrubs the
///    outgoing messages, and a scrubber failure throws so no egress is sent
///    (FR-001, SC-002).
///
/// It ships no second policy engine, approval dispatcher, or provider
/// transport: pi owns execution, this only supplies hook bodies (FR-001).
library;

import 'dart:convert';

import 'package:pi/pi.dart';

import '../approvals/approval_gate.dart';
import '../artifacts/artifact_router.dart';
import '../extensions/zuraffa_extension.dart';
import '../governance/entities/governance_policy.dart';
import '../governance/policy_resolver.dart';
import '../observability/audit_recorder.dart';
import '../observability/secret_scrubber.dart';
import '../ports/agent_approval_port.dart';
import '../ports/agent_artifact_port.dart';
import '../ports/agent_telemetry_port.dart';

/// Builds the governance [ZuraffaExtension] from a policy and host ports.
class GovernanceExtension {
  const GovernanceExtension();

  /// The fail-closed message substituted for content that cannot be scrubbed.
  static const String _failClosedText =
      'tool result withheld: governance redaction failed';

  /// Creates the governance extension for [policy].
  ///
  /// [telemetry] receives audit rows; [artifacts] stores oversized results;
  /// [approvals] presents high-tier approvals. Any may be omitted — a missing
  /// artifact/approval port yields the typed fail-closed path rather than a
  /// silent pass. [scrubber] defaults to [SecretScrubber.defaults].
  static ZuraffaExtension create(
    GovernancePolicy policy, {
    AgentTelemetryPort? telemetry,
    AgentArtifactPort? artifacts,
    AgentApprovalPort? approvals,
    SecretScrubber? scrubber,
    PolicyResolver resolver = const PolicyResolver(),
  }) {
    final merged = resolver.merge([policy]);
    final effectiveScrubber = scrubber ?? SecretScrubber.defaults();
    final audit = telemetry == null
        ? null
        : AuditRecorder(telemetry: telemetry);
    final router = ArtifactRouter(
      port: artifacts,
      threshold: resolver.oversizedThreshold(merged),
    );
    final gate = ApprovalGate(port: approvals);

    Future<BeforeToolCallResult?> beforeToolCall(
      BeforeToolCallContext ctx, {
      bool Function()? isAborted,
    }) async {
      final tool = ctx.toolName;
      if (resolver.isDenied(merged, tool)) {
        audit?.recordOutcome(phase: 'tool-call', outcome: 'deny');
        return BeforeToolCallResult(
          block: const TextBlock('tool denied by governance policy'),
          reason: 'tool "$tool" denied by governance policy',
        );
      }
      if (resolver.requiresApproval(merged, tool)) {
        final outcome = await gate.request(
          ApprovalRequest(
            toolName: tool,
            tier: resolver.tierOf(merged, tool),
            deadline: const Duration(minutes: 5),
            args: ctx.args,
          ),
        );
        return _approvalResult(audit, tool, outcome);
      }
      audit?.recordOutcome(phase: 'tool-call', outcome: 'allow');
      return null;
    }

    Future<AfterToolCallResult?> afterToolCall(
      AfterToolCallContext ctx, {
      bool Function()? isAborted,
    }) async {
      final original = ctx.result.content;
      final List<ContentBlock> scrubbed;
      try {
        scrubbed = _scrubBlocks(effectiveScrubber, original);
      } on SecretScrubberError {
        audit?.recordOutcome(
          phase: 'tool-call',
          outcome: 'failClosed',
          error: 'redaction failed',
        );
        return const AfterToolCallResult(
          content: [TextBlock(_failClosedText)],
          isError: true,
          terminate: true,
        );
      }
      final changed = !_sameContent(original, scrubbed);

      final byteSize = _byteSize(scrubbed);
      if (byteSize > router.threshold) {
        final routing = await router.route(ctx.toolName, _bytes(scrubbed));
        switch (routing) {
          case InlineArtifact(:final bytes):
            return AfterToolCallResult(
              content: [TextBlock(utf8.decode(bytes))],
            );
          case ArtifactRefOutcome(:final ref):
            audit?.recordOutcome(
              phase: 'artifact-route',
              outcome: 'artifactRef',
              redacted: changed,
            );
            return AfterToolCallResult(
              content: [TextBlock(ref.summary)],
              details: ref,
            );
          case MissingArtifactPortOutcome():
            audit?.recordOutcome(
              phase: 'artifact-route',
              outcome: 'missingArtifactPort',
            );
            return const AfterToolCallResult(
              content: [
                TextBlock('oversized result withheld: no artifact port'),
              ],
              isError: true,
              terminate: true,
            );
        }
      }

      audit?.recordOutcome(
        phase: 'tool-call',
        outcome: changed ? 'redact' : 'allow',
        redacted: changed,
      );
      return AfterToolCallResult(content: scrubbed);
    }

    Future<List<AgentMessage>> transformContext(
      List<AgentMessage> messages, {
      bool Function()? isAborted,
    }) async {
      final out = <AgentMessage>[];
      var changed = false;
      for (final message in messages) {
        try {
          out.add(
            _scrubMessage(
              effectiveScrubber,
              message,
              onChanged: () => changed = true,
            ),
          );
        } on SecretScrubberError {
          audit?.recordOutcome(
            phase: 'provider-request',
            outcome: 'failClosed',
            error: 'egress sanitization failed',
          );
          rethrow; // fail closed: no egress request is sent (SC-002).
        }
      }
      audit?.recordOutcome(
        phase: 'provider-request',
        outcome: changed ? 'redact' : 'allow',
        redacted: changed,
      );
      return out;
    }

    return ZuraffaExtension(
      id: 'zuraffa-governance',
      beforeToolCall: beforeToolCall,
      afterToolCall: afterToolCall,
      transformContext: transformContext,
    );
  }

  static BeforeToolCallResult? _approvalResult(
    AuditRecorder? audit,
    String tool,
    ApprovalOutcome outcome,
  ) {
    switch (outcome) {
      case ApprovalGranted():
        audit?.recordOutcome(phase: 'approval', outcome: 'approvalGranted');
        return null;
      case ApprovalDenied():
        audit?.recordOutcome(phase: 'approval', outcome: 'approvalDenied');
        return BeforeToolCallResult(
          block: const TextBlock('tool denied: approval denied'),
          reason: 'tool "$tool" denied: approval denied',
        );
      case ApprovalExpired():
        audit?.recordOutcome(phase: 'approval', outcome: 'approvalExpired');
        return BeforeToolCallResult(
          block: const TextBlock('tool denied: approval expired'),
          reason: 'tool "$tool" denied: approval expired',
        );
      case MissingApprovalPort():
        audit?.recordOutcome(
          phase: 'approval',
          outcome: 'missingApprovalPort',
          error: 'missingApprovalPort',
        );
        return BeforeToolCallResult(
          block: const TextBlock('tool denied: no approval port'),
          reason: 'tool "$tool" denied: missing approval port',
        );
      case DurableUnavailable():
        audit?.recordOutcome(phase: 'approval', outcome: 'durableUnavailable');
        return BeforeToolCallResult(
          block: const TextBlock('tool denied: durable approvals unavailable'),
          reason: 'tool "$tool" denied: durable approvals unavailable (pi#12)',
        );
    }
  }

  static List<ContentBlock> _scrubBlocks(
    SecretScrubber scrubber,
    List<ContentBlock> blocks, {
    void Function()? onChanged,
  }) {
    final out = <ContentBlock>[];
    for (final block in blocks) {
      switch (block) {
        case TextBlock(:final text):
          final scrubbed = scrubber.scrub(text);
          if (scrubbed != text) onChanged?.call();
          out.add(TextBlock(scrubbed));
        case ImageBlock():
          out.add(block);
      }
    }
    return out;
  }

  static AgentMessage _scrubMessage(
    SecretScrubber scrubber,
    AgentMessage m, {
    void Function()? onChanged,
  }) {
    switch (m) {
      case UserMessage(:final content):
        return UserMessage(
          content: _scrubBlocks(scrubber, content, onChanged: onChanged),
        );
      case ToolResultMessage(
        :final toolCallId,
        :final toolName,
        :final content,
        :final isError,
      ):
        return ToolResultMessage(
          toolCallId: toolCallId,
          toolName: toolName,
          content: _scrubBlocks(scrubber, content, onChanged: onChanged),
          isError: isError,
        );
      case AssistantMessage(
        :final id,
        :final content,
        :final stopReason,
        :final usage,
      ):
        final scrubbed = <dynamic>[];
        for (final block in content) {
          if (block is TextBlock) {
            final text = scrubber.scrub(block.text);
            if (text != block.text) onChanged?.call();
            scrubbed.add(TextBlock(text));
          } else {
            scrubbed.add(block);
          }
        }
        return AssistantMessage(
          id: id,
          content: scrubbed,
          stopReason: stopReason,
          usage: usage,
        );
      case CustomMessage():
        return m;
    }
  }

  static bool _sameContent(List<ContentBlock> a, List<ContentBlock> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x is TextBlock && y is TextBlock) {
        if (x.text != y.text) return false;
      } else if (x is! ImageBlock || y is! ImageBlock) {
        return false;
      }
    }
    return true;
  }

  static int _byteSize(List<ContentBlock> blocks) => blocks.fold<int>(
    0,
    (sum, b) => switch (b) {
      TextBlock(:final text) => sum + utf8.encode(text).length,
      ImageBlock(:final base64Data) => sum + base64Data.length,
    },
  );

  /// The raw bytes a host persists for an oversized result. Mirrors
  /// [_byteSize]'s block handling: text is its UTF-8 encoding, an image is its
  /// decoded base64 — never the `TextBlock(...)` debug representation, so a
  /// resolved artifact round-trips to the original content.
  static List<int> _bytes(List<ContentBlock> blocks) => blocks
      .expand<int>(
        (b) => switch (b) {
          TextBlock(:final text) => utf8.encode(text),
          ImageBlock(:final base64Data) => base64.decode(base64Data),
        },
      )
      .toList();
}
