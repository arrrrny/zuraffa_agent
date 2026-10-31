// Issue #135 — UsageLedger.prune: retention over the read-only projection.
//
// Spec 083 made the ledger an immutable value object, so prune() returns a
// NEW pruned projection and leaves the receiver untouched.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

UsageEntry entry(String id, DateTime at, {int tokens = 1}) => UsageEntry(
  id: id,
  timestamp: at,
  record: UsageLedgerEntry(
    id: '${id}_record',
    timestamp: at,
    callId: id,
    turnNumber: 1,
    inputTokens: tokens,
    outputTokens: tokens,
    cacheReadTokens: 0,
    cacheWriteTokens: 0,
  ),
);

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 5);
  final t2 = DateTime.utc(2026, 1, 10);
  final now = DateTime.utc(2026, 1, 16);

  UsageLedger seeded() => UsageLedger([
    entry('old', t0, tokens: 10),
    entry('mid', t1, tokens: 20),
    entry('new', t2, tokens: 30),
  ]);

  test('maxAge drops entries older than the cutoff', () {
    final ledger = seeded();

    // cutoff = now - 6 days = 2026-01-10: old/mid prune, new sits exactly
    // at the cutoff and survives (the age rule is strictly-older).
    final pruned = ledger.prune(
      const RetentionPolicy(maxAge: Duration(days: 6)),
      now: now,
    );

    expect(pruned.entries.map((e) => e.id), ['new']);
    expect(pruned.totalInputTokens, 30);
  });

  test('maxCount keeps the newest entries', () {
    final pruned = seeded().prune(const RetentionPolicy(maxCount: 1), now: now);

    expect(pruned.entries.map((e) => e.id), ['new']);
    expect(pruned.totalTokens, 60);
  });

  test('maxBytes drops oldest entries until the serialized size fits', () {
    final ledger = UsageLedger([
      entry('old', t0, tokens: 1000),
      entry('mid', t1, tokens: 1000),
      entry('new', t2, tokens: 1),
    ]);
    const policy = RetentionPolicy(maxBytes: 300);

    final pruned = ledger.prune(policy, now: now);

    expect(pruned.entries.map((e) => e.id), ['new']);
  });

  test('prune never mutates the receiver (spec 083 immutability)', () {
    final ledger = seeded();

    final pruned = ledger.prune(const RetentionPolicy(maxCount: 1), now: now);

    expect(ledger.length, 3);
    expect(pruned.length, 1);
    expect(pruned, isNot(equals(ledger)));
  });

  test('unlimited policy returns an equal ledger', () {
    final ledger = seeded();

    final pruned = ledger.prune(const RetentionPolicy.unlimited(), now: now);

    expect(pruned, equals(ledger));
    expect(
      identical(pruned, ledger),
      isFalse,
      reason: 'a new projection is built, contents equal',
    );
  });

  test('pruned projection preserves insertion order of survivors', () {
    final pruned = seeded().prune(const RetentionPolicy(maxCount: 2), now: now);

    expect(pruned.entries.map((e) => e.id), ['mid', 'new']);
  });
}
