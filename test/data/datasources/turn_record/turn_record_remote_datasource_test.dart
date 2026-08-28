// Regression tests for the TurnRecord remote data source.
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

import 'package:zuraffa_agent/src/domain/entities/turn_record/turn_record.dart';
import 'package:zuraffa_agent/src/data/datasources/turn_record/turn_record_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/turn_record/turn_record_remote_datasource.dart';

TurnRecord make(String id, {int turnNumber = 1}) => TurnRecord(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      turnNumber: turnNumber,
      messageEntryIds: const ['m1'],
      toolInvocationEntryIds: const ['t1'],
      stopReason: 'stop',
      startedAt: DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.fromMillisecondsSinceEpoch(10),
      durationMs: 10,
    );

void main() {
  group('TurnRecordRemoteDataSource — contract', () {
    test('is a TurnRecordDataSource', () {
      expect(
        TurnRecordRemoteDataSource(),
        isA<TurnRecordDataSource>(),
      );
    });

    test('create upserts and returns the stored entity', () async {
      final ds = TurnRecordRemoteDataSource();
      final created = await ds.create(make('a'));
      expect(created.id, 'a');
      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched, same(created));
    });

    test('get throws StateError for a missing id', () async {
      final ds = TurnRecordRemoteDataSource();
      expect(
        () => ds.get(QueryParams(params: {'id': 'nope'})),
        throwsA(isA<StateError>()),
      );
    });

    test('getList reflects the store, honoring offset/limit', () async {
      final ds = TurnRecordRemoteDataSource();
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
      final ds = TurnRecordRemoteDataSource();
      await ds.create(make('a', turnNumber: 1));

      final updated = await ds.update(
        UpdateParams(
          id: 'a',
          data: TurnRecordPatch().withTurnNumber(9),
        ),
      );
      expect(updated.turnNumber, 9);

      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched.turnNumber, 9);
    });

    test('update throws StateError when the id is missing', () async {
      final ds = TurnRecordRemoteDataSource();
      expect(
        () => ds.update(
          UpdateParams(
            id: 'ghost',
            data: TurnRecordPatch().withTurnNumber(2),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('delete removes the entity from the store', () async {
      final ds = TurnRecordRemoteDataSource();
      await ds.create(make('a'));
      await ds.delete(DeleteParams(id: 'a'));
      expect(
        () => ds.get(QueryParams(params: {'id': 'a'})),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('TurnRecordRemoteDataSource — durable JSONL persistence', () {
    late final String path;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('tr_ds_');
      path = '${dir.path}/turn_records.jsonl';
    });

    tearDownAll(() async {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (await parent.exists()) await parent.delete();
    });

    test('persists a created record across instances', () async {
      final a = TurnRecordRemoteDataSource(path: path);
      await a.create(make('p1', turnNumber: 1));

      final b = TurnRecordRemoteDataSource(path: path);
      final fetched = await b.get(QueryParams(params: {'id': 'p1'}));
      expect(fetched.id, 'p1');
      expect(fetched.turnNumber, 1);
    });

    test('persists updates and deletes across instances', () async {
      final a = TurnRecordRemoteDataSource(path: path);
      await a.create(make('p2', turnNumber: 1));
      await a.update(
        UpdateParams(id: 'p2', data: TurnRecordPatch().withTurnNumber(7)),
      );

      final b = TurnRecordRemoteDataSource(path: path);
      final updated = await b.get(QueryParams(params: {'id': 'p2'}));
      expect(updated.turnNumber, 7);

      await b.delete(DeleteParams(id: 'p2'));
      final c = TurnRecordRemoteDataSource(path: path);
      expect(
        () => c.get(QueryParams(params: {'id': 'p2'})),
        throwsA(isA<StateError>()),
      );
    });
  });
}
