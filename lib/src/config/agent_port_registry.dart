/// The bundle of host-injected ports (FR-006, data-model.md).
///
/// All seven ports are **required, non-nullable** constructor arguments, so a
/// missing port is a compile error at the composition root rather than a runtime
/// outcome — which is what FR-006's "no global service-locator fallback" means
/// in practice. There is no `missingPort` check: the type system already proves
/// it unreachable.
library;

import '../ports/agent_approval_port.dart';
import '../ports/agent_artifact_port.dart';
import '../ports/agent_credential_port.dart';
import '../ports/agent_egress_port.dart';
import '../ports/agent_lifecycle_port.dart';
import '../ports/agent_storage_port.dart';
import '../ports/agent_telemetry_port.dart';

/// The seven technology-agnostic ports a host injects to open a runtime.
class AgentPortRegistry {
  final AgentCredentialPort credentials;
  final AgentStoragePort storage;
  final AgentEgressPort egress;
  final AgentTelemetryPort telemetry;
  final AgentArtifactPort artifacts;
  final AgentApprovalPort approvals;
  final AgentLifecyclePort lifecycle;

  const AgentPortRegistry({
    required this.credentials,
    required this.storage,
    required this.egress,
    required this.telemetry,
    required this.artifacts,
    required this.approvals,
    required this.lifecycle,
  });
}
