/// zuraffa_agent — a thin, zfa-native Zuraffa wrapper around pi (issue #204).
///
/// The package opens a pi runtime from injected host configuration, installs
/// Zuraffa capability extensions through one seam composed into pi's real
/// `AgentOptions` hooks, and returns pi's own conversations (and, once pi#12
/// lands, submissions, watches, tasks, and outcomes). pi owns every agent loop,
/// provider call, transcript, compaction, and durable scheduler; this package
/// carries none of them.
///
/// Hosts compose the package through explicit dependency injection
/// ([AgentPortRegistry] + [AgentRuntimeConfig] -> [ZuraffaAgent] /
/// [AgentRuntimeFactory]), or register it additively via [ZuraffaAgentPackageModule].
library;

// Runtime module + DI registrar (the scaffolded PackageModule seam, FR-007).
export 'src/di/zuraffa_agent_package_registrar.dart';
export 'src/module/zuraffa_agent_package_module.dart';

// Runtime facade + factory (FR-003).
export 'src/runtime/agent_runtime_factory.dart';
export 'src/runtime/zuraffa_agent.dart';

// Configuration + host-injection ports (FR-006).
export 'src/config/agent_port_registry.dart';
export 'src/ports/agent_approval_port.dart';
export 'src/ports/agent_artifact_port.dart';
export 'src/ports/agent_credential_port.dart';
export 'src/ports/agent_egress_port.dart';
export 'src/ports/agent_lifecycle_port.dart';
export 'src/ports/agent_storage_port.dart';
export 'src/ports/agent_telemetry_port.dart';

// Extension-installation seam (FR-009).
export 'src/extensions/agent_extension_hooks.dart';
export 'src/extensions/extension_bootstrap.dart';
export 'src/extensions/zuraffa_extension.dart';

// pi construction boundary (FR-005).
export 'src/pi/pi_runtime_adapter.dart';

// Zorphy-generated data entities (constitution IX).
export 'src/domain/entities/agent_artifact_descriptor/agent_artifact_descriptor.dart';
export 'src/domain/entities/agent_runtime_config/agent_runtime_config.dart';

// pi's own types the wrapper hands back — re-exported so hosts need not depend
// on pi directly (FR-005: the package declares pi and re-exports its types).
export 'package:pi/pi.dart';
