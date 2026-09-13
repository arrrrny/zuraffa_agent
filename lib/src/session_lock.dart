// SessionLock — advisory single-writer sidecar lock for session stores
// (spec 114, issue #136).
//
// Quarantined dart:io usage (Constitution VII) — this file is an
// interface-backed adapter like jsonl_session_storage.dart.
//
// Contract: `acquire` takes an exclusive non-blocking OS lock on a
// `<path>.lock` sidecar; a second writer on the same path fails fast
// with a StateError naming the path (fail-closed beats silent
// interleaving). The sidecar file itself may outlive the store (stale
// sidecars are harmless — the OS lock, not the file's existence, is the
// gate). Platforms without file locking degrade to unlocked operation:
// the in-process mutex (package:synchronized) still serializes
// same-isolate mutations.

import 'dart:io';

class SessionLock {
  SessionLock(this.path);

  /// The store path being guarded — the sidecar is `<path>.lock`.
  final String path;

  RandomAccessFile? _lockFile;
  bool _held = false;

  /// Process-global registry: canonical path -> held lock. POSIX file
  /// locks are per-process, so a second in-process writer would
  /// re-acquire the OS lock trivially — this map is the in-process
  /// half of the single-writer contract (the OS lock covers
  /// cross-process writers).
  static final Map<String, SessionLock> _heldLocks = {};

  /// Whether the lock is currently held.
  bool get isHeld => _held;

  /// Takes the exclusive lock or throws [StateError] naming the path
  /// when another writer holds it.
  Future<void> acquire() async {
    if (_held) return;
    final canonical = File(path).absolute.path;
    final existing = _heldLocks[canonical];
    if (existing != null && existing != this) {
      throw StateError(
        'session path is locked by another writer: $path '
        '(single-writer contract, spec 114)',
      );
    }
    final sidecar = File('$path.lock');
    final RandomAccessFile raf;
    try {
      raf = await sidecar.open(mode: FileMode.writeOnlyAppend);
    } on FileSystemException catch (e) {
      throw StateError(
        'session path cannot be locked (sidecar open failed): $path — $e',
      );
    }
    try {
      await raf.lock(FileLock.exclusive);
    } on FileSystemException {
      await raf.close();
      throw StateError(
        'session path is locked by another writer: $path '
        '(single-writer contract, spec 114)',
      );
    } on UnsupportedError {
      // Platform without advisory file locking: degrade to unlocked
      // (the in-process mutex still serializes same-isolate writers).
      await raf.close();
      _held = false;
      return;
    }
    _lockFile = raf;
    _held = true;
    _heldLocks[canonical] = this;
  }

  /// The canonical path key for the process-global registry.
  String get _canonicalPath => File(path).absolute.path;

  /// Releases the lock. Idempotent; the sidecar file is removed on a
  /// best-effort basis (stale sidecars are harmless).
  Future<void> release() async {
    if (!_held) return;
    final raf = _lockFile;
    _lockFile = null;
    _held = false;
    _heldLocks.remove(_canonicalPath);
    try {
      await raf?.unlock();
    } catch (_) {
      // Unlock is best-effort; close below is the real release.
    }
    try {
      await raf?.close();
    } catch (_) {}
    try {
      await File('$path.lock').delete();
    } catch (_) {}
  }
}
