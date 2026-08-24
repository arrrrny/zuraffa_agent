// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Concrete provider stub for the SessionTreeEntry data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/session_tree_entry/session_tree_entry.dart';
import '../../../domain/services/session_tree_entry_service.dart';

class SessionTreeEntryProvider
    with Loggable, FailureHandler
    implements SessionTreeEntryService {
  SessionTreeEntryProvider();

  @override
  Future<SessionTreeEntry> current(NoParams params) async =>
      throw UnimplementedError('Implement SessionTreeEntryProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SessionTreeEntryProvider.count');
}
