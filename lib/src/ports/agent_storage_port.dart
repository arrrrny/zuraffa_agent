/// Host-injection port for storage / environment (FR-006).
///
/// Returns pi's own [SessionStorage] directly — the wrapper defines no storage
/// handle of its own (architecture plan §7.5). The host supplies the production
/// adapter (JSONL, Hive, remote); tests use [InMemoryAgentStoragePort].
library;

import 'package:pi/pi.dart';

/// Opens the transcript/session store the pi runtime persists to.
abstract class AgentStoragePort {
  /// Opens a fresh pi [SessionStorage].
  Future<SessionStorage> open();

  /// Releases any resources held by the host adapter.
  Future<void> close();
}

/// Pure-Dart in-memory [AgentStoragePort] backed by pi's
/// [InMemorySessionStorage].
class InMemoryAgentStoragePort implements AgentStoragePort {
  SessionStorage? _storage;

  @override
  Future<SessionStorage> open() async {
    final storage = InMemorySessionStorage();
    await storage.init();
    _storage = storage;
    return storage;
  }

  @override
  Future<void> close() async {
    await _storage?.close();
    _storage = null;
  }
}
