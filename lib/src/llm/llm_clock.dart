// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.

/// Injectable clock + sleep seam so retry/backoff schedules are deterministic
/// under test (spec 007 FR-006; constitution VII: pure Dart, no dart:io).
abstract interface class LlmClock {
  DateTime now();
  Future<void> sleep(int milliseconds);
}

/// Real-time clock backed by `Future.delayed` (pure Dart core, no dart:io).
class SystemLlmClock implements LlmClock {
  const SystemLlmClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Future<void> sleep(int milliseconds) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));
}
