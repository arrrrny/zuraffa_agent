// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider for the SessionTreeEntry data layer. Returns the active
// tree entry snapshot for the running mission. Replaces the previous stub
// (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/session_tree_entry/session_tree_entry.dart';
import '../../../domain/services/session_tree_entry_service.dart';

class SessionTreeEntryProvider
    with Loggable, FailureHandler
    implements SessionTreeEntryService {
  final SessionTreeEntry _active;

  SessionTreeEntryProvider([SessionTreeEntry? active])
      : _active = active ??
            const SessionTreeEntry(
              id: 'entry-default',
              sessionId: 'session-default',
              createdAt: 0,
            );

  @override
  Future<SessionTreeEntry> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
