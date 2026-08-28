// Regression tests for the ToolInvocationRecord remote data source.
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

import 'package:zuraffa_agent/src/domain/entities/tool_invocation_record/tool_invocation_record.dart';
import 'package:zuraffa_agent/src/data/datasources/tool_invocation_record/tool_invocation_record_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/tool_invocation_record/tool_invocation_record_remote_datasource.dart';

ToolInvocationRecord make(String id, {String toolName = 'grep'}) =>
    ToolInvocationRecord(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      toolCallId: 'call-$id',
      toolName: toolName,
      isError: false,
      durationMs: 12,
    );

void main() {
  group('ToolInvocationRecordRemoteDataSource — contract', () {
    test('is a ToolInvocationRecordDataSource', () {
      expect(
        ToolInvocationRecordRemoteDataSource(),
        isA<ToolInvocationRecordDataSource>(),
      );
    });

    test('create upserts and returns the stored entity', () async {
      final ds = ToolInvocationRecordRemoteDataSource();
      final created = await ds.create(make('a'));
      expect(created.id, 'a');
      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched, same(created));
    });

    test('get throws StateError for a missing id', () async {
      final ds = ToolInvocationRecordRemoteDataSource();
      expect(
        () => ds.get(QueryParams(params: {'id': 'nope'})),
        throwsA(isA<StateError>()),
      );
    });

    test('getList reflects the store, honoring offset/limit', () async {
      final ds = ToolInvocationRecordRemoteDataSource();
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
      final ds = ToolInvocationRecordRemoteDataSource();
      await ds.create(make('a', toolName: 'grep'));

      final updated = await ds.update(
        UpdateParams(
          id: 'a',
          data: ToolInvocationRecordPatch().withToolName('ripgrep'),
        ),
      );
      expect(updated.toolName, 'ripgrep');

      final fetched = await ds.get(QueryParams(params: {'id': 'a'}));
      expect(fetched.toolName, 'ripgrep');
    });

    test('update throws StateError when the id is missing', () async {
      final ds = ToolInvocationRecordRemoteDataSource();
      expect(
        () => ds.update(
          UpdateParams(
            id: 'ghost',
            data: ToolInvocationRecordPatch().withToolName('x'),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('delete removes the entity from the store', () async {
      final ds = ToolInvocationRecordRemoteDataSource();
      await ds.create(make('a'));
      await ds.delete(DeleteParams(id: 'a'));
      expect(
        () => ds.get(QueryParams(params: {'id': 'a'})),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ToolInvocationRecordRemoteDataSource — durable JSONL persistence', () {
    late final String path;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('tir_ds_');
      path = '${dir.path}/tool_invocations.jsonl';
    });

    tearDownAll(() async {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (await parent.exists()) await parent.delete();
    });

    test('persists a created record across instances', () async {
      final a = ToolInvocationRecordRemoteDataSource(path: path);
      await a.create(make('p1', toolName: 'grep'));

      final b = ToolInvocationRecordRemoteDataSource(path: path);
      final fetched = await b.get(QueryParams(params: {'id': 'p1'}));
      expect(fetched.id, 'p1');
      expect(fetched.toolName, 'grep');
    });

    test('persists updates and deletes across instances', () async {
      final a = ToolInvocationRecordRemoteDataSource(path: path);
      await a.create(make('p2', toolName: 'grep'));
      await a.update(
        UpdateParams(
          id: 'p2',
          data: ToolInvocationRecordPatch().withToolName('ripgrep'),
        ),
      );

      final b = ToolInvocationRecordRemoteDataSource(path: path);
      final updated = await b.get(QueryParams(params: {'id': 'p2'}));
      expect(updated.toolName, 'ripgrep');

      await b.delete(DeleteParams(id: 'p2'));
      final c = ToolInvocationRecordRemoteDataSource(path: path);
      expect(
        () => c.get(QueryParams(params: {'id': 'p2'})),
        throwsA(isA<StateError>()),
      );
    });
  });
}
