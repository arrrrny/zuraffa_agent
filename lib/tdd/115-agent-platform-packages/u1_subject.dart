// GENERATED STUB — hand-stepped (spec 115 U1): the host seam contract.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/zuraffa_agent.dart';

/// Subject for behavior U1 — declared contract:
/// `getAgentHome() -> Future<String?>`.
///
/// Reads the home through the CURRENT binding; a call on the unbound
/// default surfaces its UnimplementedError to the test.
Future<String?> subject_u1() => AgentPlatformBinding.instance.getAgentHome();
