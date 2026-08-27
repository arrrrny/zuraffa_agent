// Test helper: deterministic LlmClock (spec 007) — records sleep calls
// instead of waiting, so retry backoff schedules are observable assertions.

import 'package:zuraffa_agent/src/llm/llm_clock.dart';

class FakeLlmClock implements LlmClock {
  final List<int> sleeps = [];
  DateTime _now = DateTime.utc(2026, 1, 1);

  @override
  DateTime now() => _now;

  @override
  Future<void> sleep(int milliseconds) async {
    sleeps.add(milliseconds);
    _now = _now.add(Duration(milliseconds: milliseconds));
  }
}
