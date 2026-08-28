// HAND-CURATED — replaces the previous stub that threw.
//
// Durable local backing for the TurnRecord data source. When [path] is null
// (tests / ephemeral runs) it behaves as a volatile in-memory store, keeping
// engine tests deterministic and free of platform I/O. When [path] is provided
// it persists to a JSONL file via the allowlisted JsonlEntityStorage adapter
// (Constitution VII: platform I/O is confined to consciously allowlisted
// adapters). Real remote backing (HTTP/gRPC) remains a later phase.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/turn_record/turn_record.dart';
import '../jsonl_entity_storage.dart';
import 'turn_record_datasource.dart';

class TurnRecordRemoteDataSource
    with Loggable, FailureHandler
    implements TurnRecordDataSource {
  final String? path;
  final JsonlEntityStorage<TurnRecord>? _storage;
  final Map<String, TurnRecord> _mem = <String, TurnRecord>{};

  TurnRecordRemoteDataSource({this.path})
      : _storage = path == null
            ? null
            : JsonlEntityStorage<TurnRecord>(
                path: path,
                fromJson: TurnRecord.fromJson,
                toJson: (r) => r.toJson(),
                getId: (r) => r.id,
              );

  @override
  Future<TurnRecord> get(QueryParams<TurnRecord> params) async {
    final id = params.params?['id'] as String?;
    final found = await _read(id);
    if (found == null) {
      throw StateError('TurnRecord not found: $id');
    }
    return found;
  }

  @override
  Future<List<TurnRecord>> getList(
    ListQueryParams<TurnRecord> params,
  ) async {
    var items = await _all();
    final offset = params.offset ?? 0;
    if (offset > 0) items = items.skip(offset).toList();
    final limit = params.limit;
    if (limit != null) items = items.take(limit).toList();
    return items;
  }

  @override
  Future<TurnRecord> create(TurnRecord turnRecord) async {
    if (_storage != null) return _storage.put(turnRecord);
    _mem[turnRecord.id] = turnRecord;
    return turnRecord;
  }

  @override
  Future<TurnRecord> update(
    UpdateParams<String, TurnRecordPatch> params,
  ) async {
    final existing = await _read(params.id);
    if (existing == null) {
      throw StateError('TurnRecord not found: ${params.id}');
    }
    final updated = existing.patchWithTurnRecord(params.data);
    if (_storage != null) return _storage.put(updated);
    _mem[params.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(DeleteParams<String> params) async {
    if (_storage != null) return _storage.delete(params.id);
    _mem.remove(params.id);
  }

  Future<TurnRecord?> _read(String? id) async {
    if (id == null) return null;
    if (_storage != null) return _storage.get(id);
    return _mem[id];
  }

  Future<List<TurnRecord>> _all() async {
    if (_storage != null) return _storage.getAll();
    return _mem.values.toList();
  }
}
