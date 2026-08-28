// Spec 077 — memory distiller: automatic promotion session → long-term.
//
// RED phase: written BEFORE the implementation exists. The library
// lib/src/engine/memory_distiller.dart does not exist yet — this run must
// fail (missing library), proving test-first order.

import 'dart:io';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/agent_memory.dart';
import 'package:zuraffa_agent/src/engine/memory_distiller.dart';
import 'package:zuraffa_agent/src/engine/persistent_agent_memory.dart';

void main() {
  MemorySource src() => MemorySource(agentName: 'distiller-test');

  MemoryRecord rec(
    String id,
    String content, {
    double salience = 0.5,
    DateTime? createdAt,
    Set<String> tags = const {},
  }) =>
      MemoryRecord(
        id: id,
        content: content,
        tags: tags,
        source: src(),
        salience: salience,
        createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
      );

  AgentMemorySystem systemWith({
    List<MemoryRecord> longTerm = const [],
    Map<String, List<MemoryRecord>> sessions = const {},
  }) {
    final system = AgentMemorySystem();
    for (final r in longTerm) {
      system.remember(r, sessionId: null);
    }
    sessions.forEach((sessionId, records) {
      for (final r in records) {
        system.remember(r, sessionId: sessionId);
      }
    });
    return system;
  }

  group('spec 077 — distiller', () {
    test('DistillationPolicy defaults and validation', () {
      final defaults = DistillationPolicy();
      expect(defaults.salienceThreshold, equals(0.7));
      expect(defaults.maxPerSession, isNull);
      expect(defaults, equals(DistillationPolicy()));
      expect(DistillationPolicy(salienceThreshold: 0.9).hashCode,
          isNot(equals(defaults.hashCode)));

      expect(() => DistillationPolicy(salienceThreshold: 1.5),
          throwsArgumentError);
      expect(() => DistillationPolicy(maxPerSession: 0),
          throwsArgumentError);
    });

    test('distills a mixed-salience session — gate, identity, residue', () {
      final system = systemWith(sessions: {
        's-1': [
          rec('good-1', 'User prefers tab indentation', salience: 0.9),
          rec('good-2', 'Deployments run on Fridays', salience: 0.7),
          rec('weak-1', 'casual smalltalk about weather', salience: 0.3),
          rec('weak-2', 'typos in an early draft', salience: 0.69),
        ],
      });
      final distiller = MemoryDistiller(system: system);

      final report = distiller.distill('s-1');

      expect(report.promoted, equals(['good-1', 'good-2']));
      // Identity preserved (facade promote semantics).
      final promoted = system.longTermMemory.byId('good-1')!;
      expect(promoted.content, equals('User prefers tab indentation'));
      expect(promoted.salience, equals(0.9));
      expect(promoted.createdAt, equals(DateTime.utc(2026, 1, 1)));
      // Residue: weak records stay in the session.
      expect(system.sessionMemory.forSession('s-1').map((r) => r.id),
          equals(['weak-1', 'weak-2']));
      expect(report.sessionRemaining, equals(2));
      // Full accounting.
      expect(report.skipped, hasLength(2));
      expect(
          report.skipped.map((s) => (s.id, s.reason)),
          containsAll([
            ('weak-1', SkipReason.belowThreshold),
            ('weak-2', SkipReason.belowThreshold),
          ]));
    });

    test('boundary salience equal to threshold promotes; default is 0.7',
        () {
      final system = systemWith(sessions: {
        's-1': [
          rec('at-070', 'exactly at threshold', salience: 0.70),
        ],
      });
      final distiller = MemoryDistiller(system: system); // default policy
      final report = distiller.distill('s-1');
      expect(report.promoted, equals(['at-070']));
      expect(report.skipped, isEmpty);

      // And 0.69 with the default stays put.
      final system2 = systemWith(sessions: {
        's-2': [rec('at-069', 'just under threshold', salience: 0.69)],
      });
      final report2 = MemoryDistiller(system: system2).distill('s-2');
      expect(report2.promoted, isEmpty);
      expect(report2.skipped.single.reason,
          equals(SkipReason.belowThreshold));
    });

    test('duplicate guard skips content already known to long-term', () {
      final system = systemWith(
        longTerm: [rec('lt-1', 'The user prefers concise answers')],
        sessions: {
          's-1': [
            // Same content modulo whitespace + case → duplicate.
            rec('dup-1', '  the USER prefers concise ANSWERS  ',
                salience: 0.95),
            rec('fresh-1', 'A brand-new learning', salience: 0.8),
          ],
        },
      );
      final distiller = MemoryDistiller(system: system);

      final report = distiller.distill('s-1');

      expect(report.promoted, equals(['fresh-1']));
      expect(
          report.skipped.single, equals(SkippedRecord('dup-1', SkipReason.duplicateOfLongTerm)));
      // The duplicate stayed in the session and long-term was not doubled.
      expect(system.longTermMemory.all, hasLength(2));
      expect(system.sessionMemory.forSession('s-1').map((r) => r.id),
          equals(['dup-1']));
    });

    test('same-content session siblings dedupe within one run', () {
      final system = systemWith(sessions: {
        's-1': [
          rec('first', 'Zuraffa runs on Dart 3.11', salience: 0.9),
          rec('second', 'Zuraffa runs on dart 3.11', salience: 0.85),
        ],
      });
      final report = MemoryDistiller(system: system).distill('s-1');

      expect(report.promoted, equals(['first']));
      expect(report.skipped.single,
          equals(SkippedRecord('second', SkipReason.duplicateOfLongTerm)));
      expect(system.longTermMemory.all, hasLength(1));
    });

    test('cap promotes the best N — salience desc, older first among equals',
        () {
      final system = systemWith(sessions: {
        's-1': [
          rec('mid', 'middle salience', salience: 0.8,
              createdAt: DateTime.utc(2026, 2, 1)),
          rec('top', 'top salience', salience: 0.95),
          rec('low', 'lowest candidate', salience: 0.75),
          rec('tie-new', 'same salience, newer',
              salience: 0.8, createdAt: DateTime.utc(2026, 6, 1)),
          rec('tie-old', 'same salience, older',
              salience: 0.8, createdAt: DateTime.utc(2026, 1, 1)),
        ],
      });
      final distiller = MemoryDistiller(
        system: system,
        policy: DistillationPolicy(maxPerSession: 2),
      );

      final report = distiller.distill('s-1');

      // Ranked: top (0.95), then salience 0.8 group older-first:
      // tie-old (Jan) before mid / tie-new. Cap 2 → top + tie-old.
      expect(report.promoted, equals(['top', 'tie-old']));
      expect(
          report.skipped.map((s) => (s.id, s.reason)),
          containsAll([
            ('mid', SkipReason.capReached),
            ('tie-new', SkipReason.capReached),
            ('low', SkipReason.capReached),
          ]));
      expect(report.sessionRemaining, equals(3));
    });

    test('distill is idempotent — no double promotion, no duplicates', () {
      final system = systemWith(sessions: {
        's-1': [rec('keep-1', 'durable learning', salience: 0.9)],
      });
      final distiller = MemoryDistiller(system: system);

      final first = distiller.distill('s-1');
      final second = distiller.distill('s-1');

      expect(first.promoted, equals(['keep-1']));
      expect(second.promoted, isEmpty);
      expect(second.skipped, isEmpty);
      expect(second.sessionRemaining, equals(0));
      expect(system.longTermMemory.all, hasLength(1));
    });

    test('unknown session distills to an empty report', () {
      final system = systemWith();
      final report = MemoryDistiller(system: system).distill('nope');
      expect(report.promoted, isEmpty);
      expect(report.skipped, isEmpty);
      expect(report.sessionRemaining, equals(0));
    });

    test('DistillationReport accounts for every record', () {
      final system = systemWith(sessions: {
        's-1': [
          rec('a', 'promoted one', salience: 0.9),
          rec('b', 'too weak', salience: 0.2),
          rec('c', 'capped out', salience: 0.85),
        ],
      });
      final report = MemoryDistiller(
        system: system,
        policy: DistillationPolicy(maxPerSession: 1),
      ).distill('s-1');

      // promoted + skipped == snapshot; residue consistent.
      expect(report.promoted.length + report.skipped.length, equals(3));
      expect(report.sessionRemaining, equals(2));
      // Value semantics: same content → equal; different → not equal.
      expect(
          DistillationReport(
            promoted: ['a'],
            skipped: [
              SkippedRecord('b', SkipReason.belowThreshold),
              SkippedRecord('c', SkipReason.capReached),
            ],
            sessionRemaining: 2,
          ),
          equals(report));
      expect(
          DistillationReport(
            promoted: ['a'],
            skipped: [
              SkippedRecord('b', SkipReason.belowThreshold),
            ],
            sessionRemaining: 2,
          ),
          isNot(equals(report)));
    });

    test('distilled knowledge is durable across a store rebuild', () {
      final dir = Directory.systemTemp.createTempSync('zuraffa_distill_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final ltFile = File('${dir.path}/lt.json');

      // System over the 076 persistent store.
      final system = AgentMemorySystem(
        longTerm: PersistentLongTermMemoryStore(file: ltFile),
      );
      system.remember(
          rec('lesson', 'Always run gates before pushing', salience: 0.9),
          sessionId: 's-final');
      MemoryDistiller(system: system).distill('s-final');

      // Rebuild — "the restart".
      final restored = AgentMemorySystem(
        longTerm: PersistentLongTermMemoryStore(file: ltFile)..restore(),
      );
      final hit = restored.longTermMemory.byId('lesson');
      expect(hit, isNotNull, reason: 'distilled record must be durable');
      expect(hit!.content, equals('Always run gates before pushing'));
    });
  });
}
