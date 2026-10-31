// Issue arrrrny/zuraffa_agent#132 — shared test double for the audit trail.
//
// InMemoryAuditSink collects AuditEntries in memory so tests can pin
// AuditLog behavior without touching the filesystem. It mirrors the
// AuditSink contract implemented by JsonlAuditSink.

import 'package:zuraffa_agent/src/security/audit_log.dart';

/// Collects entries in memory, oldest first.
class InMemoryAuditSink implements AuditSink {
  final List<AuditEntry> stored = [];

  @override
  Future<void> append(AuditEntry entry) async {
    stored.add(entry);
  }

  @override
  Future<List<AuditEntry>> entries() async => List.of(stored);
}
