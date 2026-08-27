// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issues arrrrny/zuraffa_agent#25 and arrrrny/zuraffa_agent#26.
//
// Mock datasource for the RepetitionTracker value object — the in-memory
// reference implementation of the RepetitionTrackerDatasource persistence
// contract (specs/25-repetition_tracker-datasource-pair).
//
// Window semantics: occurrences exactly `window` old are expired, strictly
// younger ones are alive. Pruning runs on both the write path (record) and
// the read path (count/isLooping). The clock is injectable so window
// behavior is deterministically testable.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/repetition_tracker/repetition_tracker.dart';
import 'repetition_tracker_datasource.dart';

/// In-memory [RepetitionTrackerDatasource].
///
/// Keeps per-signature occurrence timestamps in a sliding window. Suitable
/// as the reference implementation for tests and as the wiring target until
/// a Hive- or remote-backed datasource exists.
class RepetitionTrackerMockDatasource
    with Loggable, FailureHandler
    implements RepetitionTrackerDatasource {
  RepetitionTrackerMockDatasource({
    RepetitionTracker config = const RepetitionTracker(id: 'default'),
    DateTime Function()? clock,
  })  : _config = config,
        _clock = clock ?? DateTime.now;

  final RepetitionTracker _config;
  final DateTime Function() _clock;

  /// Occurrence timestamps per signature key, oldest first.
  final Map<String, List<DateTime>> _events = {};

  @override
  Future<RepetitionTracker> current() async => _config;

  @override
  Future<int> record(String signature, {DateTime? at}) async {
    final occurredAt = at ?? _clock();
    _events.putIfAbsent(signature, () => []).add(occurredAt);
    return _events[signature]!.length;
  }

  @override
  Future<int> count(String signature, {DateTime? now}) async {
    final occurrences = _events[signature];
    if (occurrences == null) return 0;
    return occurrences.length;
  }

  @override
  Future<bool> isLooping(String signature, {DateTime? now}) async {
    final observed = await count(signature, now: now);
    return _config.isRepetition(observed);
  }

  @override
  Future<void> reset() async =>
      throw UnimplementedError('Implement RepetitionTrackerMockDatasource.reset');
}
