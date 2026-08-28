# Tasks: DartIoFreeGate (static gate)

- T1 Create `lib/src/domain/entities/dart_io_free_gate/dart_io_free_gate.dart`.
- T2 Create `lib/src/domain/services/dart_io_free_gate_service.dart`.
- T3 Create `lib/src/data/providers/dart_io_free_gate/dart_io_free_gate_provider.dart`.
- T4 Create `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## TDD behavior markers (test-after plan; all DONE on master @ b9ba15c)

> Behavior ids referenced by `tdd/test-list.md` and `tdd/cycle-log.md`. Doc-only
> markers; the original T1-T7 implementation tasks above are unchanged.

- [x] [U1] `DartIoFreeGate` value equality across all four fields + hashCode — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGate equality is value-based across all fields`
- [x] [U2] `DartIoFreeGate` inequality when a field differs — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGate inequality differs when a field changes`
- [x] [U3] `DartIoFreeGateProvider` is a `DartIoFreeGateService` — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider is a DartIoFreeGateService`
- [x] [U4] `current(NoParams)` returns the default active gate — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider.current returns the active gate`
- [x] [U5] `current(NoParams)` returns the injected value object — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider honours an injected value object`
- [x] [U6] `count(NoParams)` returns 1 — `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider.count returns 1`
