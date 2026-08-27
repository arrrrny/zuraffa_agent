// Tests for lib/src/llm/persistent_episodic_memory_store.dart — Spec 010 US3
// (FR-005). Behaviors U9-U11 — see specs/010-episodic-memory/tdd/test-list.md.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/persistent_episodic_memory_store.dart';
import 'package:zuraffa_agent/src/session_storage.dart';
import 'package:zuraffa_agent/src/types.dart';

/// Minimal in-memory SessionStorage fake (the port contract; real backends
/// are the hive/jsonl IO adapters, out of scope for this spec).
class InMemorySessionStorage implements SessionStorage {
  final List<SessionTreeEntry> entries = [];
  String? activeLeafId;

  @override
  Future<StoreOpenResult> init() async => const StoreOpenResult(loadedEntriesCount: 0);

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async => entries.add(entry);

  @override
  Future<SessionTreeEntry?> getEntry(String id) async {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<List<SessionTreeEntry>> getEntries() async => List.of(entries);

  @override
  Future<String?> getActiveLeafId() async => activeLeafId;

  @override
  Future<void> setActiveLeafId(String leafId) async => activeLeafId = leafId;

  @override
  Future<void> deleteEntries(Set<String> entryIds) async =>
      entries.removeWhere((e) => entryIds.contains(e.id));

  @override
  Future<void> close() async {}
}

void main() {
  group('PersistentEpisodicMemoryStore (spec 010, U9-U11)', () {
    test('U9: add() mirrors the memory into SessionStorage as a CustomEntry', () async {
      final storage = InMemorySessionStorage();
      final store = PersistentEpisodicMemoryStore(storage: storage);

      final memory = EpisodicMemory(
        id: 'snap-abc',
        summary: '<state_snapshot><overall_goal>g</overall_goal></state_snapshot>',
        messages: [UserMessage.text('hello'), AssistantMessage.text('world')],
      );
      await store.add(memory);

      expect(storage.entries, hasLength(1));
      final entry = storage.entries.single;
      expect(entry, isA<CustomTreeEntry>());
      final record = (entry as CustomTreeEntry).record;
      expect(record.customType, 'episodic_memory');
      expect(record.id, 'snap-abc');
      final decoded = jsonDecode(record.payload) as Map<String, dynamic>;
      expect(decoded['id'], 'snap-abc');
      expect(decoded['summary'], contains('overall_goal'));
      expect((decoded['messages'] as List), hasLength(2));

      // In-memory semantics still hold immediately.
      expect(store.retrieve('snap-abc'), isNotNull);
    });

    test('U10: restore() rebuilds store entries from the storage backend in insertion order', () async {
      final storage = InMemorySessionStorage();
      final first = PersistentEpisodicMemoryStore(storage: storage);
      await first.add(EpisodicMemory(
        id: 'snap-1',
        summary: 's1',
        messages: [UserMessage.text('one')],
      ));
      await first.add(EpisodicMemory(
        id: 'snap-2',
        summary: 's2',
        messages: [UserMessage.text('two')],
      ));
      // A non-memory custom entry must be ignored by restore.
      await storage.appendEntry(CustomTreeEntry(
        id: 'other',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        record: CustomEntry(
          id: 'other',
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          customType: 'something_else',
          payload: '{}',
        ),
      ));

      // "Engine restart": a fresh store over the same storage backend.
      final restored = PersistentEpisodicMemoryStore(storage: storage);
      await restored.restore();

      expect(restored.entries.map((m) => m.id).toList(), ['snap-1', 'snap-2']);
      final rebuilt = restored.retrieve('snap-1');
      expect(rebuilt, isNotNull);
      expect(rebuilt!.summary, 's1');
      expect(rebuilt.messages, hasLength(1));
      expect((rebuilt.messages.first as UserMessage).content, isNotEmpty);
    });

    test('U11: a restored store serves retrieve-by-id and pagination like an in-memory store', () async {
      final storage = InMemorySessionStorage();
      final writer = PersistentEpisodicMemoryStore(storage: storage);
      for (var i = 1; i <= 4; i++) {
        await writer.add(EpisodicMemory(id: 'snap-$i', summary: 's$i', messages: const []));
      }

      final restored = PersistentEpisodicMemoryStore(storage: storage);
      await restored.restore();

      expect(restored.retrieve('snap-3'), isNotNull);
      expect(restored.retrieve('nope'), isNull);
      expect(
        restored.list(limit: 2, offset: 1).map((m) => m.id).toList(),
        ['snap-2', 'snap-3'],
      );
      expect(restored.list(), hasLength(4));
      // Adding after restore keeps persisting.
      await restored.add(EpisodicMemory(id: 'snap-5', summary: 's5', messages: const []));
      expect(storage.entries.whereType<CustomTreeEntry>().map((e) => e.record.id),
          contains('snap-5'));
    });
  });
}
