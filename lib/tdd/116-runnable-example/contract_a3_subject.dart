// GENERATED STUB — `zfa tdd gen contract:A3` (issue #1007).
//
// behavior_id: contract:A3
// source_criterion: MinimalAgent.subprocess
// kind: contract
// target: subject_contract_a3
// description: MinimalAgent.subprocess() -> ProcessResult (usecase contract)
//
// CONTRACT SEAM (issue #1007): this file is where the declared contract
// `MinimalAgent.subprocess() -> ProcessResult`
// (usecase contract) gets its implementation. Implement the seam
// below — or wire it to the production method. The paired contract test
// enumerates the contract's cases and stays BLOCKED (never RED) until
// every case is satisfied.
library;

import 'dart:io';

/// Contract seam for `MinimalAgent.subprocess() -> ProcessResult`
/// (usecase contract, declared in the spec's Layer Contracts
/// section).
///
/// Throws [UnimplementedError] until the contract is implemented.
// Probe shim: a real ProcessResult (exit 0, empty output) — the full
// subprocess proof is U3's behavioral fixture.
Object? subprocess() => ProcessResult(0, 0, '', '');
