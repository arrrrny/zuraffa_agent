// Regression tests for the UsageLedgerEntry remote data source.
//
// Covers each declared method against the in-memory store: create upserts and
// returns the entity, get/getList read from the store, update applies the
// patch, delete removes. Also covers durable JSONL persistence via the
// allowlisted JsonlEntityStorage adapter (Constitution VII). Replaces the
// previous throw-on-call stub.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart'
    show
        DeleteParams,
        ListQueryParams,
        QueryParams,
        UpdateParams;

import 'package:zuraffa_agent/src/domain/entities/usage_ledger_entry/usage_ledger_entry.dart';
import 'package:zuraffa_agent/src/data/datasources/usage_ledger_entry/usage_ledger_entry_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/usage_ledger_entry/usage_ledger_entry_remote_datasource.dart';

UsageLedgerEntry make(String id, {int inputTokens = 10}) => UsageLedgerEntry(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      callId: 'call-$id',
      turnNumber: 1,
      inputTokens: inputTokens,
      outputTokens: 5,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
    );

void main() {
  group('UsageLedgerEntryRemoteDataSource — contract', () {
    test('is a UsageLedgerEntryDataSource', () {
      expect(
        UsageLedgerEntryRemoteDataSource(),
        isA<UsageLedgerEntryDataSource>(),
      );
    });

    test('create upserts and returns the stored entity', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      final created = await ds.create(make('a'));
      expect(created.id, 'a');
      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched, same(created));
    });

    test('get throws StateError for a missing id', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      expect(
        () => ds.get(QueryParams(params: {'id': 'nope'})),
        throwsA(isA<StateError>()),
      );
    });

    test('getList reflects the store, honoring offset/limit', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      await ds.create(make('a'));
      await ds.create(make('b'));
      await ds.create(make('c'));

      final all = await ds.getList(const ListQueryParams());
      expect(all.map((e) => e.id), containsAll(['a', 'b', 'c']));
      expect(all.length, 3);

      final limited = await ds.getList(const ListQueryParams(limit: 1));
      expect(limited.length, 1);
    });

    test('update applies the patch and returns the updated entity', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      await ds.create(make('a', inputTokens: 10));

      final updated = await ds.update(
        UpdateParams(
          id: 'a',
          data: UsageLedgerEntryPatch().withInputTokens(99),
        ),
      );
      expect(updated.inputTokens, 99);

      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched.inputTokens, 99);
    });

    test('update throws StateError when the id is missing', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      expect(
        () => ds.update(
          UpdateParams(
            id: 'ghost',
            data: UsageLedgerEntryPatch().withInputTokens(1),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('delete removes the entity from the store', () async {
      final ds = UsageLedgerEntryRemoteDataSource();
      await ds.create(make('a'));
      await ds.delete(DeleteParams(id: 'a'));
      expect(
        () => ds.get(QueryParams(params: {'id': 'a'})),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('UsageLedgerEntryRemoteDataSource — durable JSONL persistence', () {
    late final String path;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('ule_ds_');
      path = '${dir.path}/usage_ledger.jsonl';
    });

    tearDownAll(() async {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (await parent.exists()) await parent.delete();
    });

    test('persists a created entry across instances', () async {
      final a = UsageLedgerEntryRemoteDataSource(path: path);
      await a.create(make('p1', inputTokens: 10));

      final b = UsageLedgerEntryRemoteDataSource(path: path);
      final fetched = await b.get(QueryParams(params: {'id': 'p1'}));
      expect(fetched.id, 'p1');
      expect(fetched.inputTokens, 10);
    });

    test('persists updates and deletes across instances', () async {
      final a = UsageLedgerEntryRemoteDataSource(path: path);
      await a.create(make('p2', inputTokens: 10));
      await a.update(
        UpdateParams(id: 'p2', data: UsageLedgerEntryPatch().withInputTokens(99)),
      );

      final b = UsageLedgerEntryRemoteDataSource(path: path);
      final updated = await b.get(QueryParams(params: {'id': 'p2'}));
      expect(updated.inputTokens, 99);

      await b.delete(DeleteParams(id: 'p2'));
      final c = UsageLedgerEntryRemoteDataSource(path: path);
      expect(
        () => c.get(QueryParams(params: {'id': 'p2'})),
        throwsA(isA<StateError>()),
      );
    });
  });
}
