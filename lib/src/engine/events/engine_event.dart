// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#24.
//
// The zfa generator's `--sealed --generate-subs` pipeline emits each EngineEvent
// subtype as a standalone entity library that `implements EngineEvent`, but
// Dart forbids implementing/extending a sealed class outside its declaring
// library (`invalid_use_of_type_outside_library`). The 9 sibling issues
// arrrrny/zuraffa_agent#16..#24 all surface this same defect.
//
// This file is the canonical hand-curated `EngineEvent` sealed-class library
// that ships in the consuming repo until zfa ships the matching fix.
//
// Sibling PRs (#23 turn_completed, #22 tool_call_started, #21 tool_call_completed,
// #20 thinking_delta, #19 steering_injected, #18 provider_error,
// #17 mission_started, #16 mission_completed) will each add their own
// `final class <Name> extends EngineEvent` part file to this library.

library;

part 'turn_started.dart';
part 'turn_completed.dart';
part 'tool_call_started.dart';
part 'tool_call_completed.dart';
part 'thinking_delta.dart';
part 'steering_injected.dart';
part 'provider_error.dart';
part 'mission_started.dart';
part 'mission_completed.dart';

/// Sealed base for every event the agent engine emits at runtime.
///
/// Subtypes are emitted by the engine loop (issue #2 R1 engine core),
/// tools-and-mcp dispatch (issue #4 R3), and provider fallback (issue #5 R4).
/// Sealed so that downstream consumers can `switch` over the full union
/// exhaustively.
sealed class EngineEvent {
  const EngineEvent();
}
