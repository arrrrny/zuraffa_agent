// MemoryLogSink — an in-memory record collector for tests and consumers
// (spec 112). Pure Dart: no dart:io, no printing — the same delivery
// discipline as the rest of lib/.

import 'package:logging/logging.dart';

/// Collects [LogRecord]s in memory. The default sink for tests; hosts may
/// use it for buffered forwarding too.
final class MemoryLogSink {
  final List<LogRecord> _records = [];

  /// The collected records, oldest first.
  List<LogRecord> get records => List.unmodifiable(_records);

  int get length => _records.length;

  LogRecord operator [](int index) => _records[index];

  /// The first record whose message contains [fragment], or null.
  LogRecord? firstWhereMessage(String fragment) {
    for (final record in _records) {
      if (record.message.contains(fragment)) return record;
    }
    return null;
  }

  void add(LogRecord record) => _records.add(record);

  void clear() => _records.clear();
}
