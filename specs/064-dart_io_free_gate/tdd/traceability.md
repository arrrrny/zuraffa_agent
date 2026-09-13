# Traceability: 064-dart_io_free_gate

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:48a677ad4fb91331a599c52edb53633b1a39a0aa89e16a4f5f4f27c3f9599f08
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGate equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGate inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGateProvider is a DartIoFreeGateService **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGateProvider.current returns the active gate **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGateProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** DartIoFreeGateProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart`). | A6 | automated |

